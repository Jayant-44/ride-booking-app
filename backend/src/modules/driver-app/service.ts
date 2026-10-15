import { prisma } from '@/lib/clients/prisma.js';
import { NotificationService } from '../notifications/service.js';

import type { ProgressRideInput } from './schemas.js';

async function resolveDriverId(userId: string): Promise<string> {
  const driver = await prisma.driver.findUnique({
    where: { userId },
    select: { id: true },
  });
  if (!driver) throw new Error('DRIVER_NOT_FOUND');
  return driver.id;
}

export const DriverAppService = {
  async listMyAssignments(userId: string) {
    const driverId = await resolveDriverId(userId);

    return prisma.assignment.findMany({
      where: { driverId },
      orderBy: { offeredAt: 'desc' },
      take: 100,
      include: {
        ride: {
          include: {
            customer: {
              select: {
                user: { select: { fullName: true } },
              },
            },
          },
        },
        vehicle: true,
      },
    });
  },

  async getAssignmentDetail(userId: string, assignmentId: string) {
    const driverId = await resolveDriverId(userId);

    const assignment = await prisma.assignment.findFirst({
      where: { id: assignmentId, driverId },
      include: {
        ride: {
          include: {
            customer: {
              select: {
                user: { select: { fullName: true, phone: true, email: true } },
              },
            },
            statusHistory: { orderBy: { changedAt: 'asc' } },
          },
        },
        vehicle: true,
      },
    });

    if (!assignment) throw new Error('ASSIGNMENT_NOT_FOUND');

    const accepted = assignment.status === 'ACCEPTED';
    return {
      ...assignment,
      ride: {
        ...assignment.ride,
        customer: accepted
          ? assignment.ride.customer
          : { user: { fullName: assignment.ride.customer.user.fullName } },
      },
    };
  },

  async acceptAssignment(userId: string, assignmentId: string) {
    const driverId = await resolveDriverId(userId);

    const assignment = await prisma.assignment.findFirst({
      where: { id: assignmentId, driverId },
      include: {
        ride: {
          include: {
            customer: {
              select: {
                userId: true,
                user: { select: { fullName: true } },
              },
            },
          },
        },
        driver: { include: { user: { select: { fullName: true } } } },
        vehicle: true,
      },
    });

    if (!assignment) throw new Error('ASSIGNMENT_NOT_FOUND');
    if (assignment.status !== 'OFFERED') {
      throw new Error('ASSIGNMENT_NOT_OFFERED');
    }

    // First-accept-wins guard
    const existingWinner = await prisma.assignment.findFirst({
      where: {
        rideId: assignment.rideId,
        status: 'ACCEPTED',
        id: { not: assignmentId },
      },
    });

    if (existingWinner) {
      await prisma.assignment.update({
        where: { id: assignmentId },
        data: { status: 'CANCELLED', respondedAt: new Date() },
      });
      throw new Error('RIDE_ALREADY_TAKEN');
    }

    const result = await prisma.$transaction(async (tx) => {
      const updated = await tx.assignment.update({
        where: { id: assignmentId },
        data: { status: 'ACCEPTED', respondedAt: new Date() },
      });

      // Cancel all other OFFERED assignments for this ride
      await tx.assignment.updateMany({
        where: {
          rideId: assignment.rideId,
          status: 'OFFERED',
          id: { not: assignmentId },
        },
        data: { status: 'CANCELLED', respondedAt: new Date() },
      });

      await tx.ride.update({
        where: { id: assignment.rideId },
        data: { status: 'DRIVER_ASSIGNED' },
      });

      await tx.rideStatusHistory.create({
        data: {
          rideId: assignment.rideId,
          status: 'DRIVER_ASSIGNED',
          changedBy: userId,
          note: `Driver ${assignment.driver.user.fullName} accepted`,
        },
      });

      return updated;
    });

    // Notifications (best-effort)
    try {
      const driverName = assignment.driver.user.fullName;
      const plate = assignment.vehicle.plateNo;
      const customerName = assignment.ride.customer.user.fullName;

      await NotificationService.notifyCustomerOfAcceptance(
        assignment.ride.customer.userId,
        driverName,
        plate
      );

      const admins = await prisma.user.findMany({
        where: { role: 'ADMIN', status: 'ACTIVE' },
        select: { id: true },
      });

      await NotificationService.sendToUsers(
        admins.map((a) => a.id),
        {
          title: 'Driver Accepted',
          body: `${driverName} accepted ${customerName}'s ride.`,
          type: 'driver_accepted',
          data: { type: 'driver_accepted', screen: '/admin/home' },
        }
      );
    } catch (err) {
      console.error('[acceptAssignment] notify failed:', err);
    }

    return result;
  },

  async rejectAssignment(
    userId: string,
    assignmentId: string,
    reason?: string
  ) {
    const driverId = await resolveDriverId(userId);

    const assignment = await prisma.assignment.findFirst({
      where: { id: assignmentId, driverId },
      include: { ride: true },
    });

    if (!assignment) throw new Error('ASSIGNMENT_NOT_FOUND');
    if (assignment.status !== 'OFFERED') {
      throw new Error('ASSIGNMENT_NOT_OFFERED');
    }

    return prisma.$transaction(async (tx) => {
      const updated = await tx.assignment.update({
        where: { id: assignmentId },
        data: { status: 'REJECTED', respondedAt: new Date() },
      });

      const remainingOffers = await tx.assignment.count({
        where: { rideId: assignment.rideId, status: 'OFFERED' },
      });

      if (remainingOffers === 0) {
        await tx.ride.update({
          where: { id: assignment.rideId },
          data: { status: 'CONFIRMED' },
        });

        await tx.rideStatusHistory.create({
          data: {
            rideId: assignment.rideId,
            status: 'CONFIRMED',
            changedBy: userId,
            note: reason ?? 'All drivers declined, awaiting re-broadcast',
          },
        });
      }

      return updated;
    });
  },

  async progressRide(
    userId: string,
    rideId: string,
    input: ProgressRideInput
  ) {
    const driverId = await resolveDriverId(userId);

    const assignment = await prisma.assignment.findFirst({
      where: { rideId, driverId, status: 'ACCEPTED' },
      include: {
        ride: {
          include: {
            customer: { select: { userId: true } },
          },
        },
      },
    });
    if (!assignment) throw new Error('ASSIGNMENT_NOT_FOUND');

    const current = assignment.ride.status;
    const validNext: Record<string, string> = {
      DRIVER_ASSIGNED: 'EN_ROUTE',
      EN_ROUTE: 'ARRIVED',
      ARRIVED: 'IN_PROGRESS',
      IN_PROGRESS: 'COMPLETED',
    };

    if (validNext[current] !== input.status) {
      throw new Error('INVALID_STATUS_TRANSITION');
    }

    const result = await prisma.$transaction(async (tx) => {
      const updateData: any = { status: input.status };
      if (input.status === 'COMPLETED') {
        updateData.completedAt = new Date();
        await tx.driver.update({
          where: { id: driverId },
          data: { totalTrips: { increment: 1 } },
        });
      }

      const updated = await tx.ride.update({
        where: { id: rideId },
        data: updateData,
      });

      await tx.rideStatusHistory.create({
        data: {
          rideId,
          status: input.status as any,
          changedBy: userId,
          note: input.note ?? `Driver marked as ${input.status}`,
        },
      });

      return updated;
    });

    try {
      const statusMessage: Record<string, string> = {
        EN_ROUTE: 'Your driver is on the way.',
        ARRIVED: 'Your driver has arrived.',
        IN_PROGRESS: 'Your ride has started.',
        COMPLETED: 'Your ride is complete. Please rate your driver.',
      };

      await NotificationService.notifyCustomerOfRideStatus(
        assignment.ride.customer.userId,
        input.status,
        statusMessage[input.status] ?? 'Ride status updated.'
      );
    } catch (err) {
      console.error('[progressRide] notify failed:', err);
    }

    return result;
  },
};