import { Router } from 'express';

import { requireAuth } from '@/middlewares/auth.middleware.js';
import { requireAdmin } from '@/middlewares/admin.middleware.js';

import {
  createDriverController,
  listDriversController,
  availableDriversController,
  assignDriverController,
} from './controller.js';

const router = Router();

// Admin-only routes (all driver management is admin-operated for now)
router.use(requireAuth);
router.use(requireAdmin);

router.post('/', createDriverController);
router.get('/', listDriversController);
router.get('/available/:id', availableDriversController);
router.post('/assign/:id', assignDriverController);

export default router;