import { Router } from 'express';

/**
 * Parcha Express Router para manejar automáticamente errores async
 * Compatible con Express 5 - reemplazo directo de express-async-errors
 */

// Guarda las funciones originales
const originalRouterMethods = {
	get: Router.prototype.get,
	post: Router.prototype.post,
	put: Router.prototype.put,
	patch: Router.prototype.patch,
	delete: Router.prototype.delete,
	use: Router.prototype.use,
	all: Router.prototype.all,
};

// Función para envolver handlers
function wrapHandler(handler: any) {
	if (typeof handler !== 'function') return handler;

	// Detectar si es un error handler (4 parámetros) o middleware normal (3 parámetros)
	if (handler.length === 4) {
		// Error handler: (err, req, res, next)
		return function wrappedErrorHandler(err: any, req: any, res: any, next: any) {
			try {
				const result = handler(err, req, res, next);
				// Si es una promesa, capturar errores
				if (result && typeof result.catch === 'function') {
					result.catch(next);
				}
				return result;
			} catch (error) {
				return next(error);
			}
		};
	} else {
		// Middleware normal: (req, res, next)
		return async function wrappedHandler(req: any, res: any, next: any) {
			try {
				const result = await handler(req, res, next);
				return result;
			} catch (error) {
				return next(error);
			}
		};
	}
}

// Función para envolver todos los handlers de una ruta
function wrapHandlers(handlers: any[]): any[] {
	return handlers.map(wrapHandler);
}

// Parchar métodos HTTP
(['get', 'post', 'put', 'patch', 'delete', 'all'] as const).forEach((method) => {
	Router.prototype[method] = function (this: any, ...args: any[]) {
		const path = args[0];
		const handlers = args.slice(1);

		return originalRouterMethods[method].call(this, path, ...wrapHandlers(handlers));
	};
});

Router.prototype.use = function (this: any, ...args: any[]) {
	// Si el primer argumento es un string, es un path
	if (typeof args[0] === 'string') {
		const path = args[0];
		const handlers = args.slice(1);
		return originalRouterMethods.use.call(this, path, ...wrapHandlers(handlers));
	} else {
		// Solo handlers
		return originalRouterMethods.use.call(this, ...wrapHandlers(args));
	}
};
