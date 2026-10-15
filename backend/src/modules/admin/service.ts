import { prisma } from '@/lib/clients/prisma.js';
import { NotificationService } from '../notifications/service.js';

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
      orderBy: { scheduledAt: 'asc' },
      take: 200,
      include: {
        customer: {
          include: {
            user: { select: { fullName: true, email: true, phone: true } },
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
            user: { select: { fullName: true, email: true, phone: true } },
          },
        },
        invoice: true,
        assignments: {
          include: {
            driver: {
              include: { user: { select: { fullName: true, phone: true } } },
            },
            vehicle: true,
          },
        },
        statusHistory: { orderBy: { changedAt: 'asc' } },
      },
    });

    if (!ride) throw new Error('RIDE_NOT_FOUND');
    return ride;
  },

  async approveRide(adminId: string, rideId: string) {
    const ride = await prisma.ride.findUnique({
      where: { id: rideId },
      include: { customer: { select: { userId: true } } },
    });
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

    try {
      await NotificationService.rideReviewed(ride.customer.userId, rideId);
    } catch (err) {
      console.error('[approveRide] notify failed:', err);
    }

    return updated;
  },

  async rejectRide(adminId: string, rideId: string, reason?: string) {
    const ride = await prisma.ride.findUnique({
      where: { id: rideId },
      include: { customer: { select: { userId: true } } },
    });
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

    try {
      await NotificationService.notifyCustomerOfRideStatus(
        ride.customer.userId,
        'REJECTED',
        `Your ride request was rejected.${reason ? ' Reason: ' + reason : ''}`
      );
    } catch (err) {
      console.error('[rejectRide] notify failed:', err);
    }

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
    const ride = await prisma.ride.findUnique({
      where: { id: rideId },
      include: { customer: { select: { userId: true } } },
    });
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

    const invoice = await prisma.$transaction(async (tx) => {
      const inv = await tx.invoice.create({
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

      return inv;
    });

    try {
      const total = (totalCents / 100).toFixed(2);
      const sym = input.currencyCode === 'INR' ? '₹' : '$';
      await NotificationService.rideInvoiceSent(
        ride.customer.userId,
        invoice.invoiceNo,
        `${sym}${total}`
      );
    } catch (err) {
      console.error('[createInvoiceForRide] notify failed:', err);
    }

    return invoice;
  },

  async broadcastToDrivers(adminId: string, rideId: string) {
    const ride = await prisma.ride.findUnique({
      where: { id: rideId },
      include: {
        customer: {
          select: {
            userId: true,
            user: { select: { fullName: true } },
          },
        },
      },
    });
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

    const busyDriverIds = await prisma.assignment
      .findMany({
        where: {
          status: 'ACCEPTED',
          ride: { scheduledAt: { gte: windowStart, lte: windowEnd } },
        },
        select: { driverId: true },
      })
      .then((rows) => rows.map((r) => r.driverId));

    const availableDrivers = await prisma.driver.findMany({
      where: {
        status: 'ACTIVE',
        isAvailable: true,
        id: { notIn: busyDriverIds },
      },
      include: {
        user: { select: { id: true, fullName: true } },
        vehicles: { where: { active: true }, take: 1 },
      },
    });

    if (availableDrivers.length === 0) {
      throw new Error('NO_DRIVERS_AVAILABLE');
    }

    const created = await prisma.$transaction(async (tx) => {
      const offers = [];
      for (const driver of availableDrivers) {
        const vehicle = driver.vehicles[0];
        if (!vehicle) continue;

        const offer = await tx.assignment.create({
          data: {
            rideId,
            driverId: driver.id,
            vehicleId: vehicle.id,
            status: 'OFFERED',
            assignedByAdminId: adminId,
          },
        });
        offers.push(offer);
      }

      await tx.ride.update({
        where: { id: rideId },
        data: { status: 'DRIVER_OFFERED' },
      });

      await tx.rideStatusHistory.create({
        data: {
          rideId,
          status: 'DRIVER_OFFERED',
          changedBy: adminId,
          note: `Broadcast to ${offers.length} drivers`,
        },
      });

      return offers;
    });

        // Notify every driver — include date/time in the body
    const customerName = ride.customer.user.fullName;
    const d = ride.scheduledAt;
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const hour12 = d.getHours() % 12 || 12;
    const ampm = d.getHours() >= 12 ? 'PM' : 'AM';
    const timeLabel =
      `${days[d.getDay()]}, ${d.getDate()} ${months[d.getMonth()]} · ` +
      `${hour12}:${String(d.getMinutes()).padStart(2, '0')} ${ampm}`;

    try {
      await Promise.all(
        availableDrivers.map((driver) =>
          NotificationService.sendToUser(driver.user.id, {
            title: 'New Ride Available',
            body: `${timeLabel} · ${customerName} · ${ride.pickupAddress}`,
            type: 'ride_broadcast',
            data: {
              type: 'ride_broadcast',
              rideId,
              screen: '/driver/home',
            },
          })
        )
      );
    } catch (err) {
      console.error('[broadcastToDrivers] notify failed:', err);
    }     

    return { broadcast: created.length };
  },

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
    if (user.status !== 'PENDING') throw new Error('USER_NOT_PENDING');
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