import { prisma } from '@/lib/clients/prisma.js';

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
                // Only share the customer's name here — full details after accept
                user: {
                  select: { fullName: true },
                },
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
                user: {
                  select: {
                    fullName: true,
                    phone: true,
                    email: true,
                  },
                },
              },
            },
            statusHistory: { orderBy: { changedAt: 'asc' } },
          },
        },
        vehicle: true,
      },
    });

    if (!assignment) throw new Error('ASSIGNMENT_NOT_FOUND');

    // Only reveal customer contact AFTER acceptance
    const accepted = assignment.status === 'ACCEPTED';
    return {
      ...assignment,
      ride: {
        ...assignment.ride,
        customer: accepted
          ? assignment.ride.customer
          : {
              user: { fullName: assignment.ride.customer.user.fullName },
            },
      },
    };
  },

  async acceptAssignment(userId: string, assignmentId: string) {
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
        data: {
          status: 'ACCEPTED',
          respondedAt: new Date(),
        },
        include: {
          ride: {
            include: {
              customer: {
                select: {
                  user: {
                    select: { fullName: true, phone: true, email: true },
                  },
                },
              },
            },
          },
          vehicle: true,
        },
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
          note: 'Driver accepted the ride',
        },
      });

      return updated;
    });
  },

  async rejectAssignment(userId: string, assignmentId: string, reason?: string) {
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
        data: {
          status: 'REJECTED',
          respondedAt: new Date(),
        },
      });

      // Ride goes back to CONFIRMED so admin can reassign
      await tx.ride.update({
        where: { id: assignment.rideId },
        data: { status: 'CONFIRMED' },
      });

      await tx.rideStatusHistory.create({
        data: {
          rideId: assignment.rideId,
          status: 'CONFIRMED',
          changedBy: userId,
          note: reason ?? 'Driver rejected, awaiting reassignment',
        },
      });

      return updated;
    });
  },

  async progressRide(userId: string, rideId: string, input: ProgressRideInput) {
    const driverId = await resolveDriverId(userId);

    // Confirm the driver is assigned to this ride
    const assignment = await prisma.assignment.findFirst({
      where: {
        rideId,
        driverId,
        status: 'ACCEPTED',
      },
      include: { ride: true },
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

    return prisma.$transaction(async (tx) => {
      const updateData: any = { status: input.status };
      if (input.status === 'COMPLETED') {
        updateData.completedAt = new Date();

        // Bump driver stats
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
  },
};