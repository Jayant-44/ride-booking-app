#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

/**
 * Clase para validar especificaciones OpenAPI
 */
class OpenAPIValidator {
	constructor() {
		this.problems = [];
		this.warnings = [];
	}

	/**
	 * Reinicia el estado del validador
	 */
	reset() {
		this.problems = [];
		this.warnings = [];
	}

	/**
	 * Valida un objeto OpenAPI y retorna el resultado
	 * @param {object} openapi - El objeto OpenAPI a validar
	 * @param {string} moduleName - Nombre del módulo (para logs)
	 * @returns {{ isValid: boolean, problems: string[], warnings: string[] }}
	 */
	validate(openapi, moduleName = 'unknown') {
		this.reset();
		this.checkObject(openapi, 'root', moduleName);
		return {
			isValid: this.problems.length === 0,
			problems: [...this.problems],
			warnings: [...this.warnings],
		};
	}

	/**
	 * Verifica recursivamente un objeto en busca de problemas
	 */
	checkObject(obj, currentPath = 'root', moduleName = 'unknown') {
		if (!obj || typeof obj !== 'object') return;

		// Problema 1: Array sin items
		if (obj.type === 'array' && !obj.items) {
			this.problems.push(`[${moduleName}] ${currentPath}: Array sin 'items' definido`);
		}

		// Problema 2: items de array con solo additionalProperties: true
		if (obj.items && obj.items.type === 'object') {
			const hasProps = obj.items.properties && Object.keys(obj.items.properties).length > 0;
			const hasRef = obj.items.$ref || obj.items.allOf || obj.items.oneOf || obj.items.anyOf;
			const hasAdditional = obj.items.additionalProperties === true;

			if (!hasProps && !hasRef && hasAdditional) {
				this.problems.push(
					`[${moduleName}] ${currentPath}.items: Array items con type: "object" y solo additionalProperties: true. ` +
						`Esto causa el error "Cannot convert undefined or null to object". ` +
						`Solución: Define properties o usa un $ref a un schema`
				);
			}
		}

		// Problema 3: properties vacío
		if (obj.properties && Object.keys(obj.properties).length === 0) {
			this.warnings.push(`[${moduleName}] ${currentPath}: properties está vacío {}`);
		}

		// Problema 4: allOf/oneOf/anyOf vacío
		['allOf', 'oneOf', 'anyOf'].forEach((key) => {
			if (obj[key] && (!Array.isArray(obj[key]) || obj[key].length === 0)) {
				this.problems.push(`[${moduleName}] ${currentPath}.${key}: Debe ser un array no vacío`);
			}
		});

		// Problema 5: $ref inválido
		if (obj.$ref && typeof obj.$ref !== 'string') {
			this.problems.push(`[${moduleName}] ${currentPath}.$ref: Debe ser un string`);
		}

		// Problema 6: type inválido
		// Solo validar 'type' cuando es una propiedad de schema OpenAPI, no cuando es una propiedad de negocio
		// Un schema OpenAPI con 'type' generalmente también tiene propiedades como 'properties', 'items', 'format', 'enum', etc.
		// O está dentro de un contexto de 'schema' en el path
		// Excluir objetos dentro de 'example' ya que son datos de ejemplo, no definiciones de schema
		const validTypes = ['string', 'number', 'integer', 'boolean', 'array', 'object', 'null'];
		const isInsideExample = currentPath.includes('.example');
		const isSchemaTypeProperty =
			obj.type &&
			typeof obj.type === 'string' &&
			!isInsideExample &&
			(obj.properties !== undefined ||
				obj.items !== undefined ||
				obj.format !== undefined ||
				obj.enum !== undefined ||
				obj.$ref !== undefined ||
				obj.allOf !== undefined ||
				obj.oneOf !== undefined ||
				obj.anyOf !== undefined ||
				obj.description !== undefined ||
				obj.nullable !== undefined ||
				currentPath.endsWith('.schema') ||
				currentPath.includes('.schemas.'));

		if (isSchemaTypeProperty && !validTypes.includes(obj.type) && !Array.isArray(obj.type)) {
			this.problems.push(
				`[${moduleName}] ${currentPath}.type: Tipo inválido "${obj.type}". Debe ser uno de: ${validTypes.join(', ')}`
			);
		}

		// Problema 7: enum vacío
		if (obj.enum && (!Array.isArray(obj.enum) || obj.enum.length === 0)) {
			this.problems.push(`[${moduleName}] ${currentPath}.enum: Debe ser un array no vacío`);
		}

		// Problema 8: required debe ser array de strings (solo en schemas, no en requestBody o parameters)
		// En requestBody y parameters, required es un booleano
		if (obj.required !== undefined) {
			// Si estamos en un contexto de schema (tiene properties o type: object)
			const isSchemaContext = obj.properties || obj.type === 'object' || (obj.type && obj.type !== 'array');
			// Excluir contextos donde required es booleano (requestBody, parameters)
			const isRequestBodyOrParameter =
				currentPath.includes('.requestBody') ||
				(currentPath.includes('.parameters.') && !currentPath.includes('.schema'));

			if (isSchemaContext && !isRequestBodyOrParameter) {
				if (!Array.isArray(obj.required)) {
					this.problems.push(`[${moduleName}] ${currentPath}.required: Debe ser un array`);
				} else {
					obj.required.forEach((req, idx) => {
						if (typeof req !== 'string') {
							this.problems.push(`[${moduleName}] ${currentPath}.required[${idx}]: Debe ser un string`);
						}
					});
				}
			}
		}

		// Recursión
		for (const [key, value] of Object.entries(obj)) {
			if (value && typeof value === 'object') {
				this.checkObject(value, `${currentPath}.${key}`, moduleName);
			}
		}
	}
}

/**
 * Valida el archivo OpenAPI final
 */
function validateOpenAPI() {
	console.log('🔍 Validando archivo OpenAPI...\n');

	const specDir = __dirname;
	const openapiPath = path.join(specDir, 'openapi.json');

	// 1. Verificar que existe
	if (!fs.existsSync(openapiPath)) {
		console.error(`❌ El archivo ${openapiPath} no existe`);
		process.exit(1);
	}
	console.log(`✅ Archivo encontrado: ${openapiPath}`);

	// 2. Leer y parsear
	let openapi;
	try {
		const content = fs.readFileSync(openapiPath, 'utf8');
		openapi = JSON.parse(content);
		console.log('✅ El archivo es JSON válido');
	} catch (error) {
		console.error('❌ Error al parsear el JSON:', error.message);
		process.exit(1);
	}

	// 3. Validar usando la clase
	console.log('\n🔍 Analizando estructura...\n');
	const validator = new OpenAPIValidator();
	const result = validator.validate(openapi, 'openapi.json');

	// Mostrar warnings
	if (result.warnings.length > 0) {
		result.warnings.forEach((warning) => {
			console.warn(`⚠️  ADVERTENCIA: ${warning}`);
		});
	}

	// Mostrar errores
	if (result.problems.length > 0) {
		result.problems.forEach((problem) => {
			console.error(`❌ PROBLEMA: ${problem}`);
		});
		console.error('\n❌ Se encontraron problemas que impedirán que Orval funcione');
		console.error('   Por favor corrige los errores arriba antes de ejecutar Orval\n');
		process.exit(1);
	} else {
		console.log('\n✅ No se encontraron problemas obvios en el OpenAPI');
		console.log('   El archivo debería funcionar con Orval\n');
	}
}

// Ejecutar si se llama directamente
if (require.main === module) {
	validateOpenAPI();
}

module.exports = OpenAPIValidator;
