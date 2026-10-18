import fs from 'fs';
import path from 'path';
import pino from 'pino';
import { env } from './env.js';

// Use process.cwd() for CommonJS compatibility
const logDirectory: string = path.join(process.cwd(), 'logs');
const combinedLogPath: string = path.join(logDirectory, 'combined');
const errorLogPath: string = path.join(logDirectory, 'error');

// Crear las carpetas de logs si no existen
if (!fs.existsSync(combinedLogPath)) {
	fs.mkdirSync(combinedLogPath, { recursive: true });
}
if (!fs.existsSync(errorLogPath)) {
	fs.mkdirSync(errorLogPath, { recursive: true });
}

const logLevel = env.logLevel || 'info';
const isDev = env.nodeEnv === 'development';

const formatStackTrace = (stack: string): string => {
	if (!stack) return '';
	return stack
		.split('\n')
		.map((line, index) => {
			if (index === 0) return `    ${line}`;
			return `    ${line.trim()}`;
		})
		.join('\n');
};

const pinoConfig: pino.LoggerOptions = {
	level: logLevel,
	transport: isDev
		? {
				target: 'pino-pretty',
				options: {
					colorize: true,
					ignore: 'pid,hostname,time',
					messageFormat: '{msg}',
				},
			}
		: {
				targets: [
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

const logger = pino(pinoConfig);

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

const createGlobalLogger = (): any => {
	const globalLogger = {
		trace: (message: string | unknown, meta?: unknown): void => {
			if (typeof message !== 'string') logger.trace({ data: message }, serializeValue(message));
			else if (meta !== undefined && meta !== null) {
				if (typeof meta === 'object' && !Array.isArray(meta) && Object.keys(meta as object).length > 0) logger.trace(meta, message);
				else logger.trace({ data: meta }, `${message} ${serializeValue(meta)}`);
			} else logger.trace(message);
		},
		debug: (message: string | unknown, meta?: unknown): void => {
			if (typeof message !== 'string') logger.debug({ data: message }, serializeValue(message));
			else if (meta !== undefined && meta !== null) {
				if (typeof meta === 'object' && !Array.isArray(meta) && Object.keys(meta as object).length > 0) logger.debug(meta, message);
				else logger.debug({ data: meta }, `${message} ${serializeValue(meta)}`);
			} else logger.debug(message);
		},
		info: (message: string | unknown, meta?: unknown): void => {
			if (typeof message !== 'string') logger.info({ data: message }, serializeValue(message));
			else if (meta !== undefined && meta !== null) {
				if (typeof meta === 'object' && !Array.isArray(meta) && Object.keys(meta as object).length > 0) logger.info(meta, message);
				else logger.info({ data: meta }, `${message} ${serializeValue(meta)}`);
			} else logger.info(message);
		},
		warn: (message: string | unknown, meta?: unknown): void => {
			if (typeof message !== 'string') logger.warn({ data: message }, serializeValue(message));
			else if (meta !== undefined && meta !== null) {
				if (typeof meta === 'object' && !Array.isArray(meta) && Object.keys(meta as object).length > 0) logger.warn(meta, message);
				else logger.warn({ data: meta }, `${message} ${serializeValue(meta)}`);
			} else logger.warn(message);
		},
		error: (message: string | unknown, meta?: unknown): void => {
			if (message instanceof Error) {
				const errorMeta = { errorName: message.name, errorMessage: message.message, stack: message.stack, ...(meta && typeof meta === 'object' && !Array.isArray(meta) ? (meta as Record<string, unknown>) : {}) };
				if (isDev && message.stack) logger.error(errorMeta, `${message.name}: ${message.message}\n${formatStackTrace(message.stack)}`);
				else logger.error(errorMeta, `${message.name}: ${message.message}`);
				return;
			}
			if (typeof message !== 'string') {
				logger.error({ data: message }, serializeValue(message));
				return;
			}
			if (meta !== undefined && meta !== null) {
				if (typeof meta === 'object' && !Array.isArray(meta) && Object.keys(meta as object).length > 0) logger.error({ ...(meta as object) }, message);
				else logger.error({ data: meta }, `${message} ${serializeValue(meta)}`);
			} else logger.error(message);
		},
		fatal: (message: string | unknown, meta?: unknown): void => {
			if (message instanceof Error) {
				const errorMeta = { errorName: message.name, errorMessage: message.message, stack: message.stack, ...(meta && typeof meta === 'object' && !Array.isArray(meta) ? (meta as Record<string, unknown>) : {}) };
				logger.fatal(errorMeta, `${message.name}: ${message.message}`);
			} else if (typeof message !== 'string') logger.fatal({ data: message }, serializeValue(message));
			else if (meta !== undefined && meta !== null) {
				if (typeof meta === 'object' && !Array.isArray(meta) && Object.keys(meta as object).length > 0) logger.fatal(meta, message);
				else logger.fatal({ data: meta }, `${message} ${serializeValue(meta)}`);
			} else logger.fatal(message);
		},
		log: (message: string | unknown, ...args: unknown[]): void => {
			if (isDev) {
				if (typeof message !== 'string') logger.debug({ data: message, additionalArgs: args.length > 0 ? args : undefined }, serializeValue(message));
				else if (args.length > 0) logger.debug({ args }, message);
				else logger.debug(message);
			}
		},
		success: (message: string, meta?: Record<string, unknown>): void => {
			logger.info({ success: true, ...meta }, message);
		},
		request: (method: string, url: string, meta?: Record<string, unknown>): void => {
			logger.info({ request: true, method, url, ...meta }, `${method} ${url}`);
		},
		response: (method: string, url: string, statusCode: number, meta?: Record<string, unknown>): void => {
			const level = statusCode >= 400 ? 'error' : 'info';
			if (level === 'error') logger.error({ response: true, method, url, statusCode, ...meta }, `${method} ${url} - ${statusCode}`);
			else logger.info({ response: true, method, url, statusCode, ...meta }, `${method} ${url} - ${statusCode}`);
		},
		errorWithStack: (message: string, error: Error, meta?: Record<string, unknown>): void => {
			globalLogger.error(message, { stack: error.stack, errorName: error.name, errorMessage: error.message, ...meta });
		},
	};
	return globalLogger;
};

const globalLogger = createGlobalLogger();

declare global {
	var logger: typeof globalLogger;
}

globalThis.logger = globalLogger;

export default globalLogger;