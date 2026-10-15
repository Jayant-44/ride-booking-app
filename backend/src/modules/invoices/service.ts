import { prisma } from '@/lib/clients/prisma.js';
import { NotificationService } from '../notifications/service.js';

import type { CreateInvoiceInput, MarkPaidInput } from './schemas.js';

function generateInvoiceNo(): string {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  const rand = Math.floor(1000 + Math.random() * 9000);
  return `INV-${y}${m}${d}-${rand}`;
}

async function resolveCustomerId(userId: string): Promise<string> {
  const customer = await prisma.customer.findUnique({
    where: { userId },
    select: { id: true },
  });
  if (!customer) throw new Error('CUSTOMER_NOT_FOUND');
  return customer.id;
}

export const InvoiceService = {
  async createForRide(
    adminId: string,
    rideId: string,
    input: CreateInvoiceInput
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

    const totalCents = input.subtotalCents + input.taxCents;

    const invoice = await prisma.$transaction(async (tx) => {
      const created = await tx.invoice.create({
        data: {
          rideId,
          invoiceNo: generateInvoiceNo(),
          subtotalCents: input.subtotalCents,
          taxCents: input.taxCents,
          totalCents,
          currencyCode: input.currencyCode,
          status: 'SENT',
          sentAt: new Date(),
          dueAt: input.dueAt ? new Date(input.dueAt) : null,
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
          note: `Invoice ${created.invoiceNo} sent`,
        },
      });

      return created;
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
      console.error('[createForRide] notify failed:', err);
    }

    return invoice;
  },

  async getMyInvoices(userId: string) {
    const customerId = await resolveCustomerId(userId);

    return prisma.invoice.findMany({
      where: { ride: { customerId } },
      orderBy: { createdAt: 'desc' },
      include: {
        ride: {
          select: {
            id: true,
            pickupAddress: true,
            dropoffAddress: true,
            scheduledAt: true,
            status: true,
          },
        },
      },
    });
  },

  async getInvoiceById(userId: string, invoiceId: string) {
    const customerId = await resolveCustomerId(userId);

    const invoice = await prisma.invoice.findFirst({
      where: { id: invoiceId, ride: { customerId } },
      include: { ride: true, payment: true },
    });

    if (!invoice) throw new Error('INVOICE_NOT_FOUND');
    return invoice;
  },

  async markAsPaid(
    userId: string,
    invoiceId: string,
    input: MarkPaidInput
  ) {
    const customerId = await resolveCustomerId(userId);

    const invoice = await prisma.invoice.findFirst({
      where: { id: invoiceId, ride: { customerId } },
      include: {
        ride: {
          include: {
            customer: { select: { user: { select: { fullName: true } } } },
          },
        },
      },
    });
    if (!invoice) throw new Error('INVOICE_NOT_FOUND');
    if (invoice.status === 'PAID') throw new Error('INVOICE_ALREADY_PAID');

    const result = await prisma.$transaction(async (tx) => {
      const updatedInvoice = await tx.invoice.update({
        where: { id: invoiceId },
        data: { status: 'PAID', paidAt: new Date() },
      });

      await tx.payment.create({
        data: {
          invoiceId,
          provider: 'manual',
          providerPaymentId:
            input.providerPaymentId ?? `manual-${Date.now()}`,
          amountCents: invoice.totalCents,
          currencyCode: invoice.currencyCode,
          status: 'SUCCEEDED',
          method: input.paymentMethod ?? 'manual',
        },
      });

      await tx.ride.update({
        where: { id: invoice.rideId },
        data: { status: 'CONFIRMED', confirmedAt: new Date() },
      });

      await tx.rideStatusHistory.create({
        data: {
          rideId: invoice.rideId,
          status: 'CONFIRMED',
          changedBy: userId,
          note: 'Payment received',
        },
      });

      return updatedInvoice;
    });

    // Notify customer
    try {
      await NotificationService.notifyCustomerOfRideStatus(
        userId,
        'CONFIRMED',
        'Payment received. Your ride is confirmed!'
      );
    } catch (err) {
      console.error('[markAsPaid] customer notify failed:', err);
    }

    // Notify all admins
    try {
      const total = (invoice.totalCents / 100).toFixed(2);
      const sym = invoice.currencyCode === 'INR' ? '₹' : '$';
      const customerName = invoice.ride.customer.user.fullName;

      const admins = await prisma.user.findMany({
        where: { role: 'ADMIN', status: 'ACTIVE' },
        select: { id: true },
      });

      await NotificationService.paymentReceived(
        admins.map((a) => a.id),
        customerName,
        `${sym}${total}`
      );
    } catch (err) {
      console.error('[markAsPaid] admins notify failed:', err);
    }

    return result;
  },
};