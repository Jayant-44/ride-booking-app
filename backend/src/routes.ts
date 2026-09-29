import express from 'express';

import authRouter from './modules/auth/router.js';

const router = express.Router();

router.use('/api/auth', authRouter);

router.get('/health', (req, res) => {
  res.success({ status: 'ok', timestamp: new Date().toISOString() });
});

export default router;