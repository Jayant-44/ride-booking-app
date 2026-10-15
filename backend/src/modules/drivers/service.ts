import bcrypt from 'bcryptjs';

import { prisma } from '@/lib/clients/prisma.js';
import { NotificationService } from '../notifications/service.js';

import type { CreateDriverInput } from './schemas.js';

const SALT_ROUNDS = 10;

export const DriverService = {
  async createDriver(input: CreateDriverInput) {
    const existingUser = await prisma.user.findUnique({
      where: { email: input.email },
    });
    if (existingUser) throw new Error('EMAIL_ALREADY_EXISTS');

    const plateExists = await prisma.vehicle.findUnique({
      where: { plateNo: input.vehicle.plateNo },
    });
    if (plateExists) throw new Error('PLATE_ALREADY_EXISTS');

    const hashedPassword = await bcrypt.hash(input.password, SALT_ROUNDS);

    return prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          email: input.email,
          password: hashedPassword,
          fullName: input.fullName,
          phone: input.phone,
          role: 'DRIVER',
          timezone: input.timezone,
          currency: input.currency,
          locale: input.locale,
        },
        select: {
          id: true,
          email: true,
          fullName: true,
          phone: true,
          role: true,
        },
      });

      const driver = await tx.driver.create({
        data: {
          userId: user.id,
          licenseNo: input.licenseNo,
          licenseExpiry: new Date(input.licenseExpiry),
          isAvailable: true,
        },
      });

      const vehicle = await tx.vehicle.create({
        data: {
          driverId: driver.id,
          make: input.vehicle.make,
          model: input.vehicle.model,
          plateNo: input.vehicle.plateNo,
          color: input.vehicle.color,
          capacity: input.vehicle.capacity,
          luggageCapacity: input.vehicle.luggageCapacity,
        },
      });

      return { user, driver, vehicle };
    });
  },

  async listDrivers() {
    return prisma.driver.findMany({
      orderBy: { user: { fullName: 'asc' } },
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            email: true,
            phone: true,
            status: true,
          },
        },
        vehicles: true,
      },
    });
  },

  async getAvailableDriversForRide(rideId: string) {
    const ride = await prisma.ride.findUnique({ where: { id: rideId } });
    if (!ride) throw new Error('RIDE_NOT_FOUND');

    const windowStart = new Date(
      ride.scheduledAt.getTime() - 2 * 60 * 60 * 1000
    );
    const windowEnd = new Date(
      ride.scheduledAt.getTime() + 2 * 60 * 60 * 1000
    );

    const busyDriverIds = await prisma.assignment
      .findMany({
        where: {
          status: 'ACCEPTED',
          ride: { scheduledAt: { gte: windowStart, lte: windowEnd } },
        },
        select: { driverId: true },
      })
      .then((rows) => rows.map((r) => r.driverId));

    return prisma.driver.findMany({
      where: {
        status: 'ACTIVE',
        isAvailable: true,
        id: { notIn: busyDriverIds },
      },
      include: {
        user: { select: { fullName: true, phone: true, email: true } },
        vehicles: { where: { active: true } },
      },
    });
  },

  async assignDriver(
    adminId: string,
    rideId: string,
    driverId: string,
    vehicleId: string
  ) {
    const ride = await prisma.ride.findUnique({ where: { id: rideId } });
    if (!ride) throw new Error('RIDE_NOT_FOUND');

    if (ride.status !== 'CONFIRMED') {
      throw new Error('RIDE_NOT_CONFIRMED');
    }

    const windowStart = new Date(
      ride.scheduledAt.getTime() - 2 * 60 * 60 * 1000
    );
    const windowEnd = new Date(
      ride.scheduledAt.getTime() + 2 * 60 * 60 * 1000
    );

    const conflict = await prisma.assignment.findFirst({
      where: {
        driverId,
        status: 'ACCEPTED',
        ride: { scheduledAt: { gte: windowStart, lte: windowEnd } },
      },
    });
    if (conflict) throw new Error('DRIVER_DOUBLE_BOOKED');

    // Create the assignment inside a transaction
    const assignment = await prisma.$transaction(async (tx) => {
      const created = await tx.assignment.create({
        data: {
          rideId,
          driverId,
          vehicleId,
          status: 'OFFERED',
          assignedByAdminId: adminId,
        },
        include: {
          driver: {
            include: { user: { select: { fullName: true, phone: true } } },
          },
          vehicle: true,
        },
      });

      await tx.ride.update({
        where: { id: rideId },
        data: { status: 'DRIVER_OFFERED' },
      });

      await tx.rideStatusHistory.create({
        data: {
          rideId,
          status: 'DRIVER_OFFERED',
          changedBy: adminId,
          note: `Driver offer sent to ${created.driver.user.fullName}`,
        },
      });

      return created;
    });

    // Send push AFTER transaction (fire-and-forget)
    try {
      const driver = await prisma.driver.findUnique({
        where: { id: driverId },
        select: { userId: true },
      });

      const customer = await prisma.customer.findUnique({
        where: { id: ride.customerId },
        select: { user: { select: { fullName: true } } },
      });

      if (driver) {
        await NotificationService.notifyDriverOfOffer(
          driver.userId,
          customer?.user.fullName ?? 'A customer',
          rideId
        );
      }
    } catch (err) {
      console.error('[assignDriver] notify failed:', err);
    }

    return assignment;
  },
};