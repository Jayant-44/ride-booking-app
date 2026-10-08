import { Router } from 'express';

import { requireAuth } from '@/middlewares/auth.middleware.js';

import {
  registerController,
  registerDriverController,
  registerAdminController,
  loginController,
  meController,
} from './controller.js';

const router = Router();

// Public
router.post('/register', registerController);
router.post('/register-driver', registerDriverController);
router.post('/register-admin', registerAdminController);
router.post('/login', loginController);

// Protected
router.get('/me', requireAuth, meController);

export default router;