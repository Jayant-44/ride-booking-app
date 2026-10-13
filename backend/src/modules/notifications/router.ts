import { Router } from 'express';
import type { Request, Response } from 'express';

import { requireAuth } from '@/middlewares/auth.middleware.js';
import { prisma } from '@/lib/clients/prisma.js';
import { isFirebaseReady } from '@/lib/firebase.js';

const router = Router();

/**
 * Called by the Flutter app after login. Saves (or updates) the FCM token.
 * Body: { token: string }
 */
router.post('/register-token', requireAuth, async (req: Request, res: Response) => {
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

/**
 * Called on logout. Clears the FCM token so the user stops receiving pushes.
 */
router.post('/unregister-token', requireAuth, async (req: Request, res: Response) => {
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

export default router;