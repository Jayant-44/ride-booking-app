import { Router } from 'express';

import { requireAuth } from '@/middlewares/auth.middleware.js';

import {
  createRideController,
  listMyRidesController,
  getRideController,
  cancelRideController,
} from './controller.js';

const router = Router();

// All ride endpoints require authentication
router.use(requireAuth);

router.post('/', createRideController);
router.get('/my', listMyRidesController);
router.get('/:id', getRideController);
router.patch('/:id/cancel', cancelRideController);

export default router;