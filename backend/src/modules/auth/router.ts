import { Router } from 'express';

import { requireAuth } from '@/middlewares/auth.middleware.js';

import { registerController, loginController, meController } from './controller.js';

const router = Router();

router.post('/register', registerController);
router.post('/login', loginController);
router.get('/me', requireAuth, meController);

export default router;