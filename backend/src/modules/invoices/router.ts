import { Router } from 'express';

import { requireAuth } from '@/middlewares/auth.middleware.js';

import {
  listMyInvoicesController,
  getInvoiceController,
  markPaidController,
} from './controller.js';

const router = Router();

router.use(requireAuth);

router.get('/my', listMyInvoicesController);
router.get('/:id', getInvoiceController);
router.post('/:id/pay', markPaidController);

export default router;