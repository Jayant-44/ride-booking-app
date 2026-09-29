const fs = require('fs');
const path = require('path');

const OpenAPIValidator = require('./validate-openapi.cjs');

/**
 * Bundler para combinar módulos OpenAPI en un archivo único
 */
class OpenAPIBundler {
	constructor() {
		this.specDir = __dirname;
		this.modulesDir = path.join(this.specDir, 'modules');
		this.outputFile = path.join(this.specDir, 'openapi.json');
		this.modules = this.discoverModules();
		this.validator = new OpenAPIValidator();
		this.skippedModules = [];
		this.validModules = [];
	}

	/**
	 * Descubre automáticamente todos los módulos JSON en el directorio modules
	 */
	discoverModules() {
		try {
			if (!fs.existsSync(this.modulesDir)) {
				console.warn(`⚠️ Directorio de módulos no encontrado: ${this.modulesDir}`);
				return [];
			}

			const files = fs.readdirSync(this.modulesDir);
			const modules = files
				.filter((file) => file.endsWith('.json'))
				.map((file) => ({
					file,
					name: path.parse(file).name,
				}));

			return modules;
		} catch (error) {
			console.error('❌ Error descubriendo módulos:', error.message);
			return [];
		}
	}

	/**
	 * Lee un archivo JSON de manera síncrona
	 */
	readJsonFile(filePath) {
		try {
			const content = fs.readFileSync(filePath, 'utf8');
			return JSON.parse(content);
		} catch (error) {
			console.error(`Error leyendo archivo ${filePath}:`, error.message);
			process.exit(1);
		}
	}

	/**
	 * Combina objetos evitando duplicados
	 */
	mergeObjects(target, source, allowDuplicates = false) {
		for (const key in source) {
			if (source.hasOwnProperty(key)) {
				if (target[key] && typeof target[key] === 'object' && typeof source[key] === 'object') {
					if (Array.isArray(target[key]) && Array.isArray(source[key])) {
						// Para arrays, concatenamos y removemos duplicados si es necesario
						target[key] = target[key].concat(source[key]);
						if (!allowDuplicates) {
							target[key] = target[key].filter(
								(item, index, self) => index === self.findIndex((t) => JSON.stringify(t) === JSON.stringify(item))
							);
						}
					} else {
						// Para objetos, recursivamente combinamos
						this.mergeObjects(target[key], source[key], allowDuplicates);
					}
				} else {
					// Para valores primitivos o cuando target[key] no existe
					if (!target[key] || allowDuplicates) {
						target[key] = source[key];
					}
				}
			}
		}
		return target;
	}

	/**
	 * Crea la especificación base
	 */
	createBaseSpec() {
		return {
			openapi: '3.0.3',
			info: {
				title: 'Auth Management API',
				description: 'API para gestión de autenticación y accesos de usuarios internos y externos',
				version: '1.0.0',
				contact: {
					name: 'Auth Management Team',
					email: 'admin@authmanagement.com',
				},
			},
			servers: [
				{
					url: 'http://127.0.0.1:3053',
					description: 'Servidor de desarrollo',
				},
			],
			tags: [],
			paths: {},
			components: {
				schemas: {},
				responses: {},
				securitySchemes: {
					bearerAuth: {
						type: 'http',
						scheme: 'bearer',
						bearerFormat: 'JWT',
						description: 'JWT Bearer token para autenticación',
					},
				},
			},
		};
	}

	/**
	 * Valida que todos los módulos existan
	 */
	validateModules() {
		const missingFiles = [];

		for (const module of this.modules) {
			const filePath = path.join(this.modulesDir, module.file);
			if (!fs.existsSync(filePath)) {
				missingFiles.push(module.file);
			}
		}

		if (missingFiles.length > 0) {
			console.error('❌ Archivos faltantes:', missingFiles.join(', '));
			console.error('Por favor, asegúrate de que todos los módulos existan en:', this.modulesDir);
			process.exit(1);
		}
	}

	/**
	 * Valida un módulo OpenAPI antes de añadirlo
	 * @param {object} moduleSpec - Especificación del módulo
	 * @param {string} moduleName - Nombre del módulo
	 * @returns {boolean} - true si es válido, false si no
	 */
	validateModule(moduleSpec, moduleName) {
		const result = this.validator.validate(moduleSpec, moduleName);

		// Mostrar warnings
		if (result.warnings.length > 0) {
			result.warnings.forEach((warning) => {
				console.warn(`   ⚠️  ${warning}`);
			});
		}

		// Mostrar errores
		if (!result.isValid) {
			console.error(`   ❌ Módulo "${moduleName}" tiene errores de validación:`);
			result.problems.forEach((problem) => {
				console.error(`      • ${problem}`);
			});
			return false;
		}

		return true;
	}

	/**
	 * Construye la especificación completa
	 */
	bundle() {
		console.log('🔄 Iniciando bundling de especificaciones OpenAPI...');

		// Validar que todos los módulos existan
		this.validateModules();

		if (this.modules.length === 0) {
			console.warn('⚠️ No se encontraron módulos para procesar');
		} else {
			console.log(`📦 Módulos encontrados: ${this.modules.map((m) => m.name).join(', ')}`);
		}

		// Crear especificación base
		const combinedSpec = this.createBaseSpec();

		// Procesar cada módulo
		for (const module of this.modules) {
			console.log(`\n📁 Procesando módulo: ${module.name}`);

			const filePath = path.join(this.modulesDir, module.file);

			// Leer el módulo
			let moduleSpec;
			try {
				moduleSpec = this.readJsonFile(filePath);
			} catch (error) {
				console.error(`   ❌ Error leyendo ${module.name}: ${error.message}`);
				this.skippedModules.push({ name: module.name, reason: `Error de lectura: ${error.message}` });
				continue;
			}

			// Validar el módulo antes de añadirlo
			if (!this.validateModule(moduleSpec, module.name)) {
				this.skippedModules.push({ name: module.name, reason: 'Errores de validación OpenAPI' });
				console.error(`   ⏭️  Módulo "${module.name}" omitido por errores de validación`);
				continue;
			}

			console.log(`   ✅ Módulo "${module.name}" validado correctamente`);
			this.validModules.push(module.name);

			// Combinar tags
			if (moduleSpec.tags) {
				combinedSpec.tags = combinedSpec.tags.concat(moduleSpec.tags);
			}

			// Combinar paths
			if (moduleSpec.paths) {
				this.mergeObjects(combinedSpec.paths, moduleSpec.paths);
			}

			// Combinar components/schemas
			if (moduleSpec.components?.schemas) {
				this.mergeObjects(combinedSpec.components.schemas, moduleSpec.components.schemas);
			}

			// Combinar components/responses
			if (moduleSpec.components?.responses) {
				this.mergeObjects(combinedSpec.components.responses, moduleSpec.components.responses);
			}
		}

		// Eliminar duplicados en tags
		combinedSpec.tags = combinedSpec.tags.filter(
			(tag, index, self) => index === self.findIndex((t) => t.name === tag.name)
		);

		return combinedSpec;
	}

	/**
	 * Escribe la especificación combinada al archivo de salida
	 */
	writeOutput(spec) {
		try {
			const content = JSON.stringify(spec, null, '\t');
			fs.writeFileSync(this.outputFile, content, 'utf8');
			console.log(`✅ Especificación combinada guardada en: ${this.outputFile}`);
		} catch (error) {
			console.error('❌ Error escribiendo archivo de salida:', error.message);
			process.exit(1);
		}
	}

	/**
	 * Ejecuta el proceso completo de bundling
	 */
	run() {
		const startTime = Date.now();

		try {
			const combinedSpec = this.bundle();
			this.writeOutput(combinedSpec);

			const endTime = Date.now();
			const duration = endTime - startTime;

			console.log(`\n🎉 Bundling completado exitosamente en ${duration}ms`);
			console.log(`📊 Resumen:`);
			console.log(`   - Tags: ${combinedSpec.tags.length}`);
			console.log(`   - Paths: ${Object.keys(combinedSpec.paths).length}`);
			console.log(`   - Schemas: ${Object.keys(combinedSpec.components.schemas).length}`);
			console.log(`   - Responses: ${Object.keys(combinedSpec.components.responses).length}`);

			// Mostrar módulos procesados
			if (this.validModules.length > 0) {
				console.log(`\n✅ Módulos incluidos (${this.validModules.length}):`);
				this.validModules.forEach((name) => {
					console.log(`   • ${name}`);
				});
			}

			// Mostrar módulos omitidos
			if (this.skippedModules.length > 0) {
				console.log(`\n⚠️  Módulos omitidos (${this.skippedModules.length}):`);
				this.skippedModules.forEach(({ name, reason }) => {
					console.log(`   • ${name}: ${reason}`);
				});
			}
		} catch (error) {
			console.error('❌ Error durante el bundling:', error.message);
			process.exit(1);
		}
	}
}

// Ejecutar el bundler si se ejecuta directamente
if (require.main === module) {
	const bundler = new OpenAPIBundler();
	bundler.run();
}

module.exports = OpenAPIBundler;
