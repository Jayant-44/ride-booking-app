import pino from 'pino';

const logger = pino({
  transport:
    process.env.NODE_ENV === 'development'
      ? { target: 'pino-pretty' }
      : undefined, // Production will log raw JSON, which is better for Render
  level: process.env.LOG_LEVEL || 'info',
});

export { logger };