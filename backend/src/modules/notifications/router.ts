import { Router } from 'express';
import type { Request, Response } from 'express';

import { requireAuth } from '@/middlewares/auth.middleware.js';
import { prisma } from '@/lib/clients/prisma.js';
import { isFirebaseReady } from '@/lib/firebase.js';
import { NotificationService } from './service.js';

const router = Router();

function getUserId(req: Request): string | null {
  return (req as any).user?.id ?? null;
}

// ============================================================
// FCM TOKEN
// ============================================================

router.post('/register-token', requireAuth, async (req, res) => {
  const userId = getUserId(req);
  const { token } = req.body ?? {};

  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }
  if (!token || typeof token !== 'string') {
    res.status(400).json({ success: false, message: 'token is required' });
    return;
  }

  await prisma.user.update({
    where: { id: userId },
    data: { fcmToken: token },
  });

  res.success({ firebaseReady: isFirebaseReady() }, 'Token registered');
});

router.post('/unregister-token', requireAuth, async (req, res) => {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  await prisma.user.update({
    where: { id: userId },
    data: { fcmToken: null },
  });

  res.success(null, 'Token cleared');
});

// ============================================================
// LIST / COUNT / READ
// ============================================================

router.get('/', requireAuth, async (req, res) => {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const unreadOnly = req.query.unreadOnly === 'true';
  const list = await NotificationService.listMine(userId, unreadOnly);
  res.success(list);
});

router.get('/unread-count', requireAuth, async (req, res) => {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const count = await NotificationService.unreadCount(userId);
  res.success({ count });
});

router.patch('/:id/read', requireAuth, async (req, res) => {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  try {
    const notif = await NotificationService.markRead(
      userId,
      String(req.params.id)
    );
    res.success(notif, 'Marked as read');
  } catch (err) {
    if (err instanceof Error && err.message === 'NOTIFICATION_NOT_FOUND') {
      res
        .status(404)
        .json({ success: false, message: 'Notification not found' });
      return;
    }
    throw err;
  }
});

router.patch('/read-all', requireAuth, async (req, res) => {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const result = await NotificationService.markAllRead(userId);
  res.success(result, result.message);
});

export default router;