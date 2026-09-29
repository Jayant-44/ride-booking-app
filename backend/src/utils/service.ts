import type { ServiceResponse } from '@/types/service.js';
import type { z } from 'zod';

/**
 * Crea una respuesta de servicio validada y sanitizada para enviar al cliente
 *
 * Por defecto, elimina automáticamente propiedades no definidas en el schema
 * para evitar exponer datos sensibles o innecesarios al frontend
 *
 * @param options Objeto con message, data, schema y strict
 * @returns ServiceResponse con datos validados y sanitizados
 * @throws ZodError si los datos no cumplen con el schema o hay propiedades extra (en strict mode)
 *
 * @example
 * // Por defecto elimina propiedades no definidas (seguro)
 * return createServiceResponse({
 *   message: 'Usuario encontrado',
 *   data: userFromDB, // Puede tener password, tokens, etc.
 *   schema: UserPublicSchema // Solo id, name, email
 * });
 * // Resultado: solo propiedades definidas en UserPublicSchema
 *
 * // Modo strict: lanza error si hay propiedades extra
 * return createServiceResponse({
 *   data: userData,
 *   schema: UserSchema,
 *   strict: true // Error si userData tiene propiedades extra
 * });
 *
 * @remarks
 * Úsala siempre que devuelvas datos del servidor al cliente
 * El schema actúa como whitelist de qué datos pueden salir del servidor
 */
export function createServiceResponse<TSchema extends z.ZodSchema>(options: {
	/** Mensaje descriptivo de la operación (por defecto: "Processed successfully") */
	message?: string;
	/** Datos del servidor a enviar al cliente (validado en compile-time y runtime) */
	data: z.infer<TSchema>;
	/** Schema de Zod que define qué datos se deben enviar al cliente */
	schema: TSchema;
	/**
	 * Modo estricto: si es true, lanza error si hay propiedades extra
	 * Por defecto (false), elimina automáticamente propiedades no definidas en el schema
	 *
	 * Usa false (por defecto) para evitar exponer datos sensibles al frontend
	 */
	strict?: boolean;
}): ServiceResponse<z.infer<TSchema>> {
	const { message = 'Processed successfully', data, schema, strict = false } = options;

	if (strict) {
		// Modo strict: error si hay propiedades extra
		const strictSchema = 'strict' in schema && typeof schema.strict === 'function' ? schema.strict() : schema;
		const validatedData = strictSchema.parse(data);
		return { message, data: validatedData };
	} else {
		// Por defecto: elimina propiedades no definidas (sanitiza)
		const validatedData = schema.parse(data);
		return { message, data: validatedData };
	}
}

/**
 * Versión segura de createServiceResponse que no lanza errores
 * Retorna un objeto con el resultado de la validación
 *
 * Por defecto sanitiza los datos eliminando propiedades extra
 *
 * @param options Objeto con message, data, schema y strict
 * @returns Objeto con success y response o error
 *
 * @example
 * const result = createSafeServiceResponse({
 *   message: 'Usuario encontrado',
 *   data: userFromDB,
 *   schema: UserPublicSchema
 * });
 *
 * if (result.success) {
 *   return result.response; // Datos sanitizados
 * } else {
 *   console.error(result.error); // Error de validación
 * }
 */
export function createSafeServiceResponse<TSchema extends z.ZodSchema>(options: {
	message?: string;
	data: z.infer<TSchema>;
	schema: TSchema;
	/**
	 * Modo estricto: si es true, lanza error si hay propiedades extra
	 * Por defecto (false), elimina automáticamente propiedades no definidas
	 */
	strict?: boolean;
}): { success: true; response: ServiceResponse<z.infer<TSchema>> } | { success: false; error: z.ZodError } {
	const { message = 'Processed successfully', data, schema, strict = false } = options;

	if (strict) {
		// Modo strict: error si hay propiedades extra
		const strictSchema = 'strict' in schema && typeof schema.strict === 'function' ? schema.strict() : schema;
		const result = strictSchema.safeParse(data);

		if (!result.success) {
			return { success: false, error: result.error };
		}

		return {
			success: true,
			response: { message, data: result.data },
		};
	} else {
		// Por defecto: elimina propiedades extra
		const result = schema.safeParse(data);

		if (!result.success) {
			return { success: false, error: result.error };
		}

		return {
			success: true,
			response: { message, data: result.data },
		};
	}
}
