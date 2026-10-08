import { prisma } from '@/lib/clients/prisma.js';

import type { ListRidesQuery } from './schemas.js';

export const AdminService = {
  async listRides(query: ListRidesQuery) {
    const where: any = {};
    if (query.status) where.status = query.status;

    if (query.from || query.to) {
      where.scheduledAt = {};
      if (query.from) where.scheduledAt.gte = new Date(query.from);
      if (query.to) where.scheduledAt.lte = new Date(query.to);
    }

    return prisma.ride.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: 200,
      include: {
        customer: {
          include: {
            user: {
              select: {
                fullName: true,
                email: true,
                phone: true,
              },
            },
          },
        },
        invoice: {
          select: {
            id: true,
            invoiceNo: true,
            totalCents: true,
            currencyCode: true,
            status: true,
          },
        },
      },
    });
  },

  async getRideById(rideId: string) {
    const ride = await prisma.ride.findUnique({
      where: { id: rideId },
      include: {
        customer: {
          include: {
            user: {
              select: {
                fullName: true,
                email: true,
                phone: true,
              },
            },
          },
        },
        invoice: true,
        assignments: {
          include: {
            driver: {
              include: {
                user: {
                  select: { fullName: true, phone: true },
                },
              },
            },
            vehicle: true,
          },
        },
        statusHistory: {
          orderBy: { changedAt: 'asc' },
        },
      },
    });

    if (!ride) throw new Error('RIDE_NOT_FOUND');
    return ride;
  },

  async approveRide(adminId: string, rideId: string) {
    const ride = await prisma.ride.findUnique({ where: { id: rideId } });
    if (!ride) throw new Error('RIDE_NOT_FOUND');

    if (ride.status !== 'REQUESTED' && ride.status !== 'ADMIN_REVIEW') {
      throw new Error('RIDE_NOT_APPROVABLE');
    }

    const updated = await prisma.ride.update({
      where: { id: rideId },
      data: { status: 'ADMIN_REVIEW' },
    });

    await prisma.rideStatusHistory.create({
      data: {
        rideId,
        status: 'ADMIN_REVIEW',
        changedBy: adminId,
        note: 'Approved by admin',
      },
    });

    return updated;
  },

  async rejectRide(adminId: string, rideId: string, reason?: string) {
    const ride = await prisma.ride.findUnique({ where: { id: rideId } });
    if (!ride) throw new Error('RIDE_NOT_FOUND');

    if (ride.status === 'REJECTED' || ride.status === 'CANCELLED') {
      throw new Error('RIDE_NOT_REJECTABLE');
    }

    const updated = await prisma.ride.update({
      where: { id: rideId },
      data: { status: 'REJECTED' },
    });

    await prisma.rideStatusHistory.create({
      data: {
        rideId,
        status: 'REJECTED',
        changedBy: adminId,
        note: reason ?? 'Rejected by admin',
      },
    });

    return updated;
  },

  async getStats() {
    const [total, pending, confirmed, completed] = await Promise.all([
      prisma.ride.count(),
      prisma.ride.count({ where: { status: 'REQUESTED' } }),
      prisma.ride.count({ where: { status: 'CONFIRMED' } }),
      prisma.ride.count({ where: { status: 'COMPLETED' } }),
    ]);

    return { total, pending, confirmed, completed };
  },

  async createInvoiceForRide(
    adminId: string,
    rideId: string,
    input: { subtotalCents: number; taxCents: number; currencyCode: string }
  ) {
    const ride = await prisma.ride.findUnique({ where: { id: rideId } });
    if (!ride) throw new Error('RIDE_NOT_FOUND');

    if (ride.status !== 'ADMIN_REVIEW') {
      throw new Error('RIDE_NOT_READY_FOR_INVOICE');
    }

    const existing = await prisma.invoice.findUnique({ where: { rideId } });
    if (existing) throw new Error('INVOICE_ALREADY_EXISTS');

    const now = new Date();
    const y = now.getFullYear();
    const m = String(now.getMonth() + 1).padStart(2, '0');
    const d = String(now.getDate()).padStart(2, '0');
    const rand = Math.floor(1000 + Math.random() * 9000);
    const invoiceNo = `INV-${y}${m}${d}-${rand}`;

    const totalCents = input.subtotalCents + input.taxCents;

    return prisma.$transaction(async (tx) => {
      const invoice = await tx.invoice.create({
        data: {
          rideId,
          invoiceNo,
          subtotalCents: input.subtotalCents,
          taxCents: input.taxCents,
          totalCents,
          currencyCode: input.currencyCode,
          status: 'SENT',
          sentAt: new Date(),
        },
      });

      await tx.ride.update({
        where: { id: rideId },
        data: { status: 'QUOTED' },
      });

      await tx.rideStatusHistory.create({
        data: {
          rideId,
          status: 'QUOTED',
          changedBy: adminId,
          note: `Invoice ${invoiceNo} sent`,
        },
      });

      return invoice;
    });
  },

  // ============================================================
  // USER APPROVALS (drivers & admins)
  // ============================================================

  async listPendingUsers(role?: 'DRIVER' | 'ADMIN') {
    return prisma.user.findMany({
      where: {
        status: 'PENDING',
        ...(role ? { role } : { role: { in: ['DRIVER', 'ADMIN'] } }),
      },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        phone: true,
        fullName: true,
        role: true,
        status: true,
        createdAt: true,
        driver: {
          select: {
            licenseNo: true,
            licenseExpiry: true,
            vehicles: true,
          },
        },
      },
    });
  },

  async approveUser(
    adminId: string,
    targetUserId: string,
    adminIsSuperAdmin: boolean
  ) {
    const user = await prisma.user.findUnique({
      where: { id: targetUserId },
    });
    if (!user) throw new Error('USER_NOT_FOUND');

    if (user.status !== 'PENDING') {
      throw new Error('USER_NOT_PENDING');
    }

    if (user.role === 'ADMIN' && !adminIsSuperAdmin) {
      throw new Error('SUPER_ADMIN_REQUIRED');
    }

    const { generateUniqueId } = await import('../auth/service.js');
    const prefix = user.role === 'DRIVER' ? 'DRV' : 'ADM';
    const uniqueId = await generateUniqueId(prefix);

    return prisma.$transaction(async (tx) => {
      const updated = await tx.user.update({
        where: { id: targetUserId },
        data: {
          status: 'ACTIVE',
          uniqueId,
          approvedBy: adminId,
          approvedAt: new Date(),
        },
        select: {
          id: true,
          email: true,
          phone: true,
          fullName: true,
          role: true,
          status: true,
          uniqueId: true,
        },
      });

      if (user.role === 'DRIVER') {
        await tx.driver.update({
          where: { userId: targetUserId },
          data: { status: 'ACTIVE', isAvailable: true },
        });

        await tx.vehicle.updateMany({
          where: { driver: { userId: targetUserId } },
          data: { active: true },
        });
      }

      return updated;
    });
  },

  async rejectUser(
    adminId: string,
    targetUserId: string,
    reason?: string,
    adminIsSuperAdmin?: boolean
  ) {
    const user = await prisma.user.findUnique({
      where: { id: targetUserId },
    });
    if (!user) throw new Error('USER_NOT_FOUND');

    if (user.role === 'ADMIN' && !adminIsSuperAdmin) {
      throw new Error('SUPER_ADMIN_REQUIRED');
    }

    return prisma.user.update({
      where: { id: targetUserId },
      data: {
        status: 'SUSPENDED',
        approvedBy: adminId,
        approvedAt: new Date(),
      },
      select: {
        id: true,
        email: true,
        fullName: true,
        role: true,
        status: true,
      },
    });
  },
};