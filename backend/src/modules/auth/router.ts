import { Router } from 'express';

import { requireAuth } from '@/middlewares/auth.middleware.js';

import {
  registerController,
  registerDriverController,
  registerAdminController,
  loginController,
  meController,
  updateProfileController,
  changePasswordController,
  updateSettingsController,
} from './controller.js';

const router = Router();

// Public
router.post('/register', registerController);
router.post('/register-driver', registerDriverController);
router.post('/register-admin', registerAdminController);
router.post('/login', loginController);

// Protected
router.get('/me', requireAuth, meController);
router.patch('/me', requireAuth, updateProfileController);
router.patch('/password', requireAuth, changePasswordController);
router.patch('/settings', requireAuth, updateSettingsController);

export default router;