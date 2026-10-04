import { prisma } from '@/lib/clients/prisma.js';

import type { CreateRideInput } from './schemas.js';

export const RideService = {
  async create(userId: string, input: CreateRideInput) {
    const customer = await prisma.customer.findUnique({
      where: { userId },
    });
    if (!customer) throw new Error('CUSTOMER_NOT_FOUND');

    const ride = await prisma.ride.create({
      data: {
        customerId: customer.id,
        status: 'REQUESTED',
        pickupAddress: input.pickupAddress,
        pickupLat: input.pickupLat,
        pickupLng: input.pickupLng,
        dropoffAddress: input.dropoffAddress,
        dropoffLat: input.dropoffLat,
        dropoffLng: input.dropoffLng,
        scheduledAt: new Date(input.scheduledAt),
        passengers: input.passengers,
        luggageCount: input.luggageCount,
        vehicleType: input.vehicleType,
        notes: input.notes,
      },
    });

    await prisma.rideStatusHistory.create({
      data: {
        rideId: ride.id,
        status: 'REQUESTED',
        changedBy: userId,
        note: 'Ride created by customer',
      },
    });

    return ride;
  },

  async listMy(userId: string) {
    const customer = await prisma.customer.findUnique({
      where: { userId },
    });
    if (!customer) return [];

    return prisma.ride.findMany({
      where: { customerId: customer.id },
      orderBy: { scheduledAt: 'desc' },
      take: 50,
    });
  },

  async getOne(userId: string, rideId: string) {
    const customer = await prisma.customer.findUnique({
      where: { userId },
    });
    if (!customer) throw new Error('CUSTOMER_NOT_FOUND');

    const ride = await prisma.ride.findUnique({
      where: { id: rideId },
    });
    if (!ride || ride.customerId !== customer.id) {
      throw new Error('RIDE_NOT_FOUND');
    }
    return ride;
  },

  async cancel(userId: string, rideId: string, reason?: string) {
    const customer = await prisma.customer.findUnique({
      where: { userId },
    });
    if (!customer) throw new Error('CUSTOMER_NOT_FOUND');

    const ride = await prisma.ride.findUnique({ where: { id: rideId } });
    if (!ride || ride.customerId !== customer.id) {
      throw new Error('RIDE_NOT_FOUND');
    }

    const cancellable = [
      'REQUESTED',
      'ADMIN_REVIEW',
      'QUOTED',
      'AWAITING_PAYMENT',
    ];
    if (!cancellable.includes(ride.status)) {
      throw new Error('CANNOT_CANCEL');
    }

    const updated = await prisma.ride.update({
      where: { id: rideId },
      data: { status: 'CANCELLED' },
    });

    await prisma.rideStatusHistory.create({
      data: {
        rideId: ride.id,
        status: 'CANCELLED',
        changedBy: userId,
        note: reason ?? 'Cancelled by customer',
      },
    });

    return updated;
  },
};