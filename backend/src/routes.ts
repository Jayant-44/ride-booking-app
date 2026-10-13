import express from 'express';

import authRouter from './modules/auth/router.js';
import ridesRouter from './modules/rides/router.js';
import invoicesRouter from './modules/invoices/router.js';
import adminRouter from './modules/admin/router.js';
import driversRouter from './modules/drivers/router.js';
import driverAppRouter from './modules/driver-app/router.js';
import notificationsRouter from './modules/notifications/router.js';

const router = express.Router();

router.use('/api/auth', authRouter);
router.use('/api/rides', ridesRouter);
router.use('/api/invoices', invoicesRouter);
router.use('/api/admin', adminRouter);
router.use('/api/drivers', driversRouter);
router.use('/api/driver', driverAppRouter);
router.use('/api/notifications', notificationsRouter);

router.get('/health', (req, res) => {
  res.success({ status: 'ok', timestamp: new Date().toISOString() });
});

export default router;