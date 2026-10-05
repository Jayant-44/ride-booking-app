import express from 'express';

import authRouter from './modules/auth/router.js';
import ridesRouter from './modules/rides/router.js';
import adminRouter from './modules/admin/router.js';

const router = express.Router();

router.use('/api/auth', authRouter);
router.use('/api/rides', ridesRouter);
router.use('/api/admin', adminRouter);

router.get('/health', (req, res) => {
  res.success({ status: 'ok', timestamp: new Date().toISOString() });
});

export default router;