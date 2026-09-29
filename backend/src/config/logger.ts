import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import pino from 'pino';

import { env } from './env.js';

// Crear equivalente a __dirname para módulos ES
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Define las rutas para los archivos de logs en la raíz del proyecto
const logDirectory: string = path.join(__dirname, '../../logs');
const combinedLogPath: string = path.join(logDirectory, 'combined');
const errorLogPath: string = path.join(logDirectory, 'error');

// Crear las carpetas de logs si no existen
if (!fs.existsSync(combinedLogPath)) {
	fs.mkdirSync(combinedLogPath, { recursive: true });
}
if (!fs.existsSync(errorLogPath)) {
	fs.mkdirSync(errorLogPath, { recursive: true });
}

// Obtener configuración del entorno
const logLevel = env.logLevel;
const isDev = env.nodeEnv === 'development';

// console.log('Logger config:', { NODE_ENV: env.nodeEnv, isDev, logLevel });

// Función personalizada para formatear stack traces
const formatStackTrace = (stack: string): string => {
	if (!stack) return '';

	return stack
		.split('\n')
		.map((line, index) => {
			if (index === 0) return `    ${line}`; // Primera línea es el error message
			return `    ${line.trim()}`; // Indentar todas las líneas del stack
		})
		.join('\n');
};

// Configuración de transports para Pino
const pinoConfig: pino.LoggerOptions = {
	level: logLevel,
	transport: isDev
		? {
				target: 'pino-pretty',
				options: {
					colorize: true,
					ignore: 'pid,hostname,time',
					messageFormat: '{msg}',
					// Eliminar customPrettifiers para evitar problemas de serialización
					// El formateo se hará en el wrapper del logger
				},
			}
		: {
				targets: [
					// Transport para archivo de logs combinados
					{
						target: 'pino/file',
						level: 'info',
						options: {
							destination: path.join(
								combinedLogPath,
								`combined-${new Date()
									.toLocaleDateString('es-ES', { day: '2-digit', month: '2-digit', year: '2-digit' })
									.replace(/\//g, '-')}.log`
							),
							mkdir: true,
							encoding: 'utf8',
						},
					},

					// Transport para archivo de logs de errores
					{
						target: 'pino/file',
						level: 'error',
						options: {
							destination: path.join(
								errorLogPath,
								`error-${new Date()
									.toLocaleDateString('es-ES', { day: '2-digit', month: '2-digit', year: '2-digit' })
									.replace(/\//g, '-')}.log`
							),
							mkdir: true,
							encoding: 'utf8',
						},
					},
				],
			},
};

// Crear el logger
const logger = pino(pinoConfig);

// Función auxiliar para serializar objetos de forma segura
const serializeValue = (value: unknown): string => {
	if (value === null) return 'null';
	if (value === undefined) return 'undefined';
	if (typeof value === 'string') return value;
	if (typeof value === 'number' || typeof value === 'boolean') return String(value);
	if (value instanceof Error) {
		return `${value.name}: ${value.message}${value.stack ? '\n' + value.stack : ''}`;
	}
	try {
		return JSON.stringify(value, null, 2);
	} catch {
		return String(value);
	}
};

// Función para crear un logger global
const createGlobalLogger = (): any => {
	const globalLogger = {
		// Métodos estándar de Pino
		trace: (message: string | unknown, meta?: unknown): void => {
			if (typeof message !== 'string') {
				logger.trace({ data: message }, serializeValue(message));
			} else if (meta !== undefined && meta !== null) {
				if (typeof meta === 'object' && !Array.isArray(meta) && Object.keys(meta as object).length > 0) {
					logger.trace(meta, message);
				} else {
					logger.trace({ data: meta }, `${message} ${serializeValue(meta)}`);
				}
			} else {
				logger.trace(message);
			}
		},
		debug: (message: string | unknown, meta?: unknown): void => {
			if (typeof message !== 'string') {
				logger.debug({ data: message }, serializeValue(message));
			} else if (meta !== undefined && meta !== null) {
				if (typeof meta === 'object' && !Array.isArray(meta) && Object.keys(meta as object).length > 0) {
					logger.debug(meta, message);
				} else {
					logger.debug({ data: meta }, `${message} ${serializeValue(meta)}`);
				}
			} else {
				logger.debug(message);
			}
		},
		info: (message: string | unknown, meta?: unknown): void => {
			if (typeof message !== 'string') {
				logger.info({ data: message }, serializeValue(message));
			} else if (meta !== undefined && meta !== null) {
				if (typeof meta === 'object' && !Array.isArray(meta) && Object.keys(meta as object).length > 0) {
					logger.info(meta, message);
				} else {
					logger.info({ data: meta }, `${message} ${serializeValue(meta)}`);
				}
			} else {
				logger.info(message);
			}
		},
		warn: (message: string | unknown, meta?: unknown): void => {
			if (typeof message !== 'string') {
				logger.warn({ data: message }, serializeValue(message));
			} else if (meta !== undefined && meta !== null) {
				if (typeof meta === 'object' && !Array.isArray(meta) && Object.keys(meta as object).length > 0) {
					logger.warn(meta, message);
				} else {
					logger.warn({ data: meta }, `${message} ${serializeValue(meta)}`);
				}
			} else {
				logger.warn(message);
			}
		},
		error: (message: string | unknown, meta?: unknown): void => {
			// Si el primer parámetro es un Error, tratarlo especialmente
			if (message instanceof Error) {
				const errorMeta = {
					errorName: message.name,
					errorMessage: message.message,
					stack: message.stack,
					...(meta && typeof meta === 'object' && !Array.isArray(meta) ? (meta as Record<string, unknown>) : {}),
				};

				if (isDev && message.stack) {
					const formattedStack = formatStackTrace(message.stack);
					const finalMessage = `${message.name}: ${message.message}\n${formattedStack}`;
					logger.error(errorMeta, finalMessage);
				} else {
					logger.error(errorMeta, `${message.name}: ${message.message}`);
				}
				return;
			}

			// Si el mensaje no es un string, serializarlo
			if (typeof message !== 'string') {
				logger.error({ data: message }, serializeValue(message));
				return;
			}

			// Caso normal: message es string
			if (meta !== undefined && meta !== null) {
				// Si meta es un objeto válido con claves
				if (typeof meta === 'object' && !Array.isArray(meta) && Object.keys(meta as object).length > 0) {
					const processedMeta = { ...(meta as Record<string, unknown>) };

					// En desarrollo, formatear el stack trace en el mensaje directamente
					if (isDev && processedMeta.stack && typeof processedMeta.stack === 'string') {
						const formattedStack = formatStackTrace(processedMeta.stack);
						const enhancedMessage = `${message}\n${formattedStack}`;

						// Agregar información adicional al final del mensaje
						const additionalInfo = [];
						if (processedMeta.method) additionalInfo.push(`method: "${processedMeta.method}"`);
						if (processedMeta.url) additionalInfo.push(`url: "${processedMeta.url}"`);
						if (processedMeta.errorName) additionalInfo.push(`errorName: "${processedMeta.errorName}"`);
						if (processedMeta.errorMessage) additionalInfo.push(`errorMessage: "${processedMeta.errorMessage}"`);

						const finalMessage =
							additionalInfo.length > 0 ? `${enhancedMessage}\n    ${additionalInfo.join('\n    ')}` : enhancedMessage;

						// Remover campos que ya incluimos en el mensaje
						delete processedMeta.stack;
						delete processedMeta.method;
						delete processedMeta.url;
						delete processedMeta.errorName;
						delete processedMeta.errorMessage;

						logger.error(processedMeta, finalMessage);
					} else {
						logger.error(processedMeta, message);
					}
				} else {
					// Si meta es un valor primitivo o array, incluirlo en el mensaje
					logger.error({ data: meta }, `${message} ${serializeValue(meta)}`);
				}
			} else {
				logger.error(message);
			}
		},
		fatal: (message: string | unknown, meta?: unknown): void => {
			if (message instanceof Error) {
				const errorMeta = {
					errorName: message.name,
					errorMessage: message.message,
					stack: message.stack,
					...(meta && typeof meta === 'object' && !Array.isArray(meta) ? (meta as Record<string, unknown>) : {}),
				};
				logger.fatal(errorMeta, `${message.name}: ${message.message}`);
			} else if (typeof message !== 'string') {
				logger.fatal({ data: message }, serializeValue(message));
			} else if (meta !== undefined && meta !== null) {
				if (typeof meta === 'object' && !Array.isArray(meta) && Object.keys(meta as object).length > 0) {
					logger.fatal(meta, message);
				} else {
					logger.fatal({ data: meta }, `${message} ${serializeValue(meta)}`);
				}
			} else {
				logger.fatal(message);
			}
		},

		// Método personalizado para logs de desarrollo
		log: (message: string | unknown, ...args: unknown[]): void => {
			if (isDev) {
				if (typeof message !== 'string') {
					logger.debug({ data: message, additionalArgs: args.length > 0 ? args : undefined }, serializeValue(message));
				} else if (args.length > 0) {
					logger.debug({ args }, message);
				} else {
					logger.debug(message);
				}
			}
		},

		// Método para logs de éxito
		success: (message: string, meta?: Record<string, unknown>): void => {
			const logData = { success: true, ...meta };
			logger.info(logData, message);
		},

		// Método para request logging
		request: (method: string, url: string, meta?: Record<string, unknown>): void => {
			const logData = { request: true, method, url, ...meta };
			logger.info(logData, `${method} ${url}`);
		},

		// Método para response logging
		response: (method: string, url: string, statusCode: number, meta?: Record<string, unknown>): void => {
			const logData = { response: true, method, url, statusCode, ...meta };
			const level = statusCode >= 400 ? 'error' : 'info';
			if (level === 'error') {
				logger.error(logData, `${method} ${url} - ${statusCode}`);
			} else {
				logger.info(logData, `${method} ${url} - ${statusCode}`);
			}
		},

		// Método específico para errores con stack trace mejorado
		errorWithStack: (message: string, error: Error, meta?: Record<string, unknown>): void => {
			const logData = {
				stack: error.stack,
				errorName: error.name,
				errorMessage: error.message,
				...meta,
			};

			// Usar el método error que ya maneja el formateo
			globalLogger.error(message, logData);
		},
	};

	return globalLogger;
};

const globalLogger = createGlobalLogger();

// Hacer el logger disponible globalmente
declare global {
	var logger: typeof globalLogger;
}

globalThis.logger = globalLogger;

export default globalLogger;
