import { Router } from 'express';

import { requireAuth } from '@/middlewares/auth.middleware.js';
import { requireDriver } from '@/middlewares/driver.middleware.js';

import {
  listMyAssignmentsController,
  getAssignmentDetailController,
  acceptAssignmentController,
  rejectAssignmentController,
  progressRideController,
} from './controller.js';

const router = Router();

router.use(requireAuth);
router.use(requireDriver);

router.get('/assignments', listMyAssignmentsController);
router.get('/assignments/:id', getAssignmentDetailController);
router.patch('/assignments/:id/accept', acceptAssignmentController);
router.patch('/assignments/:id/reject', rejectAssignmentController);
router.patch('/rides/:id/status', progressRideController);

export default router;