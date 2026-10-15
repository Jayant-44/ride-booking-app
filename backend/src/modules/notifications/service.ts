import { prisma } from '@/lib/clients/prisma.js';
import { isFirebaseReady, getMessagingClient } from '@/lib/firebase.js';

interface PushPayload {
  title: string;
  body: string;
  type: string;
  data?: Record<string, string>;
}

export const NotificationService = {
  // ============================================================
  // CORE — persist to DB AND push via FCM
  // ============================================================
  async sendToUser(userId: string, payload: PushPayload) {
    // 1) Persist to DB (never fails silently)
    try {
      await prisma.notification.create({
        data: {
          userId,
          title: payload.title,
          body: payload.body,
          type: payload.type,
        },
      });
    } catch (err) {
      console.error('[notif] DB write failed:', err);
    }

    // 2) Send push (best-effort)
    try {
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { fcmToken: true },
      });
      if (!user?.fcmToken) return;
      if (!isFirebaseReady()) return;

      const messaging = getMessagingClient();
      await messaging.send({
        token: user.fcmToken,
        notification: { title: payload.title, body: payload.body },
        data: payload.data ?? {},
        android: {
          priority: 'high',
          notification: { channelId: 'rides', sound: 'default' },
        },
        apns: {
          payload: { aps: { sound: 'default', badge: 1 } },
        },
      });
    } catch (err: any) {
      if (
        err?.code === 'messaging/invalid-registration-token' ||
        err?.code === 'messaging/registration-token-not-registered'
      ) {
        await prisma.user.update({
          where: { id: userId },
          data: { fcmToken: null },
        });
      } else {
        console.error('[push] Failed to send:', err?.message ?? err);
      }
    }
  },

  async sendToUsers(userIds: string[], payload: PushPayload) {
    await Promise.all(userIds.map((id) => this.sendToUser(id, payload)));
  },

  async notifyAdmins(payload: PushPayload) {
    const admins = await prisma.user.findMany({
      where: { role: 'ADMIN', status: 'ACTIVE' },
      select: { id: true },
    });
    await this.sendToUsers(admins.map((a) => a.id), payload);
  },

  // ============================================================
  // LIST / COUNT / MARK
  // ============================================================
  async listMine(userId: string, unreadOnly = false) {
    return prisma.notification.findMany({
      where: { userId, ...(unreadOnly ? { readAt: null } : {}) },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  },

  async unreadCount(userId: string) {
    return prisma.notification.count({
      where: { userId, readAt: null },
    });
  },

  async markRead(userId: string, notificationId: string) {
    const notif = await prisma.notification.findFirst({
      where: { id: notificationId, userId },
    });
    if (!notif) throw new Error('NOTIFICATION_NOT_FOUND');

    return prisma.notification.update({
      where: { id: notificationId },
      data: { readAt: new Date() },
    });
  },

  async markAllRead(userId: string) {
    await prisma.notification.updateMany({
      where: { userId, readAt: null },
      data: { readAt: new Date() },
    });
    return { message: 'All marked as read' };
  },

  // ============================================================
  // EVENT HELPERS
  // ============================================================
  async newRideRequested(customerName: string, rideId: string) {
    await this.notifyAdmins({
      title: 'New Ride Request',
      body: `${customerName} has requested a ride. Review it now.`,
      type: 'ride_requested',
      data: { type: 'ride_requested', screen: '/admin/rides', rideId },
    });
  },

  async rideReviewed(customerUserId: string, rideId: string) {
    await this.sendToUser(customerUserId, {
      title: 'Ride Reviewed',
      body: 'Your ride request has been reviewed. Awaiting invoice.',
      type: 'ride_reviewed',
      data: { type: 'ride_reviewed', screen: '/home', rideId },
    });
  },

  async rideInvoiceSent(customerUserId: string, invoiceNo: string, total: string) {
    await this.sendToUser(customerUserId, {
      title: 'Invoice Ready',
      body: `Invoice ${invoiceNo} for ${total}. Tap to pay.`,
      type: 'invoice_sent',
      data: { type: 'invoice_sent', screen: '/home' },
    });
  },

  async paymentReceived(adminUserIds: string[], customerName: string, amount: string) {
    await this.sendToUsers(adminUserIds, {
      title: 'Payment Received',
      body: `${customerName} paid ${amount}. Assign a driver.`,
      type: 'payment_received',
      data: { type: 'payment_received', screen: '/admin/rides' },
    });
  },

  async notifyDriverOfOffer(
    driverUserId: string,
    customerName: string,
    rideId: string
  ) {
    // Fetch ride for date/time
    const ride = await prisma.ride.findUnique({
      where: { id: rideId },
      select: { scheduledAt: true, pickupAddress: true },
    });

    let timeLabel = '';
    if (ride) {
      const d = ride.scheduledAt;
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      const hour12 = d.getHours() % 12 || 12;
      const ampm = d.getHours() >= 12 ? 'PM' : 'AM';
      timeLabel =
        `${days[d.getDay()]}, ${d.getDate()} ${months[d.getMonth()]} · ` +
        `${hour12}:${String(d.getMinutes()).padStart(2, '0')} ${ampm}`;
    }

    const body = timeLabel
      ? `${timeLabel} · ${customerName} · ${ride?.pickupAddress ?? ''}`
      : `${customerName} has requested a ride. Tap to view.`;

    await this.sendToUser(driverUserId, {
      title: 'New Ride Offer',
      body,
      type: 'assignment_offer',
      data: {
        type: 'assignment_offer',
        screen: '/driver/home',
        rideId,
      },
    });
  },

  async notifyCustomerOfAcceptance(
    customerUserId: string,
    driverName: string,
    plateNo: string
  ) {
    await this.sendToUser(customerUserId, {
      title: 'Driver Assigned',
      body: `${driverName} (${plateNo}) is on the way.`,
      type: 'driver_assigned',
      data: { type: 'driver_assigned', screen: '/home' },
    });
  },

  async notifyCustomerOfRideStatus(
    customerUserId: string,
    status: string,
    message: string
  ) {
    await this.sendToUser(customerUserId, {
      title: 'Ride Update',
      body: message,
      type: `ride_${status.toLowerCase()}`,
      data: { type: 'ride_status', status, screen: '/home' },
    });
  },
};