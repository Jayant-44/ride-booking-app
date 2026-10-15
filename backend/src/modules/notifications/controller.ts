import type { Request, Response } from 'express';

import { NotificationService } from './service.js';

function getUserId(req: Request): string | null {
  return (req as any).user?.id ?? null;
}

export async function listController(req: Request, res: Response): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const unreadOnly = req.query.unreadOnly === 'true';
  const list = await NotificationService.listMine(userId, unreadOnly);
  res.success(list);
}

export async function unreadCountController(req: Request, res: Response): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const count = await NotificationService.unreadCount(userId);
  res.success({ count });
}

export async function markReadController(req: Request, res: Response): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  try {
    const notif = await NotificationService.markRead(userId, String(req.params.id));
    res.success(notif, 'Marked as read');
  } catch (err) {
    if (err instanceof Error && err.message === 'NOTIFICATION_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Notification not found' });
      return;
    }
    throw err;
  }
}

export async function markAllReadController(req: Request, res: Response): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const result = await NotificationService.markAllRead(userId);
  res.success(result, result.message);
}