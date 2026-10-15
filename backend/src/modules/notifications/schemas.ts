import { z } from 'zod';

export const CreateNotificationSchema = z.object({
  userId: z.string().min(1),
  title: z.string().min(1).max(120),
  body: z.string().min(1).max(500),
  type: z.string().min(1).max(40),
});

export const ListNotificationsQuerySchema = z.object({
  unreadOnly: z.enum(['true', 'false']).optional(),
});

export type CreateNotificationInput = z.infer<typeof CreateNotificationSchema>;
export type ListNotificationsQuery = z.infer<typeof ListNotificationsQuerySchema>;