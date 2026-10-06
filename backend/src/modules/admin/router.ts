import { Router } from 'express';

import { requireAuth } from '@/middlewares/auth.middleware.js';
import { requireAdmin } from '@/middlewares/admin.middleware.js';

import {
  listRidesController,
  getRideController,
  approveRideController,
  rejectRideController,
  statsController,
  createInvoiceController,
} from './controller.js';

const router = Router();

router.use(requireAuth);
router.use(requireAdmin);

router.get('/stats', statsController);
router.get('/rides', listRidesController);
router.get('/rides/:id', getRideController);
router.patch('/rides/:id/approve', approveRideController);
router.patch('/rides/:id/reject', rejectRideController);
router.post('/rides/:id/invoice', createInvoiceController);

export default router;