import { Router } from 'express';
import type { Request, Response } from 'express';

import { requireAuth } from '@/middlewares/auth.middleware.js';
import { prisma } from '@/lib/clients/prisma.js';
import { isFirebaseReady } from '@/lib/firebase.js';

const router = Router();

// ---------- FCM TOKEN REGISTRATION ----------

router.post('/register-token', requireAuth, async (req, res) => {
  const userId = (req as any).user?.id;
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
  const userId = (req as any).user?.id;
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

// ---------- NOTIFICATIONS LIST ----------

router.get('/', requireAuth, async (req: Request, res: Response) => {
  const userId = (req as any).user?.id;
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const notifications = await prisma.notification.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
    take: 100,
  });

  res.success(notifications);
});

// ---------- UNREAD COUNT ----------

router.get('/unread-count', requireAuth, async (req: Request, res: Response) => {
  const userId = (req as any).user?.id;
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const count = await prisma.notification.count({
    where: { userId, readAt: null },
  });

  res.success({ count });
});

// ---------- MARK ONE AS READ ----------

router.patch('/:id/read', requireAuth, async (req: Request, res: Response) => {
  const userId = (req as any).user?.id;
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const updated = await prisma.notification.updateMany({
    where: { id: String(req.params.id), userId },
    data: { readAt: new Date() },
  });

  res.success({ updated: updated.count });
});

// ---------- MARK ALL AS READ ----------

router.patch('/read-all', requireAuth, async (req: Request, res: Response) => {
  const userId = (req as any).user?.id;
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const updated = await prisma.notification.updateMany({
    where: { userId, readAt: null },
    data: { readAt: new Date() },
  });

  res.success({ updated: updated.count });
});

export default router;