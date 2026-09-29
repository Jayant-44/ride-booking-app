import { type Request, type Response, type NextFunction } from 'express';

import { AppError } from './errors.js';
import logger from '../logger.js';

function errorHandler(err: Error, req: Request, res: Response, next: NextFunction): any {
	if (res.headersSent) {
		logger.error(err.message, { stack: err.stack, method: req.method, url: req.originalUrl, headersSent: true });
		return next(err);
	}

	// Si es un error de nuestra aplicación (AppError o sus subclases)
	if (err instanceof AppError) {
		logger.warn(err.message, { stack: err.stack, method: req.method, url: req.originalUrl });

		const errorResponse = {
			success: false,
			message: err.message,
			stack: process.env.NODE_ENV === 'production' ? null : err.stack,
		};

		return res.status(err.statusCode).json(errorResponse);
	}

	// Para cualquier otro error no manejado
	logger.error(err.message, { stack: err.stack, method: req.method, url: req.originalUrl });

	const errorResponse = {
		success: false,
		message: 'Ha ocurrido un error interno. Intenta más tarde.',
		stack: process.env.NODE_ENV === 'production' ? null : err.stack,
	};

	return res.status(500).json(errorResponse);
}

export default errorHandler;
