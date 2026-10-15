import { prisma } from '@/lib/clients/prisma.js';
import { isFirebaseReady, getMessagingClient } from '@/lib/firebase.js';

interface PushPayload {
  title: string;
  body: string;
  type: string;
  data?: Record<string, string>;
}

export const NotificationService = {
  /**
   * Persist a notification row + send a push (if the user has a token).
   */
  async sendToUser(userId: string, payload: PushPayload) {
    // 1. Persist to DB so the bell icon can show it even if FCM fails
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
      console.error('[push] Failed to persist notification:', err);
    }

    // 2. Send FCM push
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
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data ?? {},
        android: {
          priority: 'high',
          notification: {
            channelId: 'rides',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: { sound: 'default', badge: 1 },
          },
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

  async notifyDriverOfOffer(driverUserId: string, customerName: string) {
    await this.sendToUser(driverUserId, {
      title: 'New Ride Offer',
      body: `${customerName} has requested a ride. Tap to view details.`,
      type: 'assignment_offer',
      data: {
        type: 'assignment_offer',
        screen: '/driver/home',
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
      body: `${driverName} (${plateNo}) is on the way to pick you up.`,
      type: 'driver_assigned',
      data: {
        type: 'driver_assigned',
        screen: '/home',
      },
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
      type: 'ride_status',
      data: {
        type: 'ride_status',
        status,
        screen: '/home',
      },
    });
  },
};