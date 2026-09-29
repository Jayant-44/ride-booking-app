# Logging con Pino

Este proyecto utiliza la librería [Pino](https://github.com/pinojs/pino) para producir logs de alto rendimiento con soporte de rotación diaria y formatos personalizables.

## 1. Variables de entorno

- `NODE_ENV` (development | production): determina si se usa salida legible en consola o archivos rotativos.
- `LOG_LEVEL` (trace | debug | info | warn | error | fatal): nivel mínimo de logs a mostrar o persistir.

## 2. Archivo de configuración

Ubicado en `src/config/logger.ts`, consta de tres этапs:

1. Creación de carpetas:
   ```ts
   const logDirectory = path.join(__dirname, '../../logs');
   const combinedLogPath = path.join(logDirectory, 'combined');
   const errorLogPath = path.join(logDirectory, 'error');
   // mkdirSync(..., { recursive: true })
   ```
2. Carga de entorno y flags:
   ```ts
   const logLevel = env.logLevel; // lee LOG_LEVEL
   const isDev = env.nodeEnv === 'development';
   ```
3. Configuración de transportes:
   - En **desarrollo** usa `pino-pretty` para colorear y traducir timestamps:
     ```ts
     transport: {
       target: 'pino-pretty',
       options: { colorize: true, translateTime: 'HH:MM:ss dd-mm-yyyy', ignore: 'pid,hostname' }
     }
     ```
   - En **producción** genera dos ficheros con rotación diaria:
     ```ts
     targets: [
     	{
     		target: 'pino/file',
     		level: 'info',
     		options: { destination: combinedLogPath + '/combined-<fecha>.log', mkdir: true },
     	},
     	{
     		target: 'pino/file',
     		level: 'error',
     		options: { destination: errorLogPath + '/error-<fecha>.log', mkdir: true },
     	},
     ];
     ```

## 3. Estructura de carpetas de logs

- `logs/combined/` → registra todos los mensajes de nivel `info` y superiores.
- `logs/error/` → registra exclusivamente errores (`error`, `fatal`).

Los nombres de fichero incluyen fecha local (dd-mm-aa) para facilitar búsqueda.

## 4. Métodos disponibles

### Métodos estándares de Pino

```ts
logger.trace(msg, meta?)
logger.debug(msg, meta?)
logger.info(msg, meta?)
logger.warn(msg, meta?)
logger.error(msg, meta?)
logger.fatal(msg, meta?)
```

- **meta**: objeto adicional que se serializa como JSON.

### Métodos extendidos

- `logger.log(message, ...args)` → alias de `debug` en desarrollo.
- `logger.success(message, meta?)` → nivel `info`, añade `{ success: true }`.
- `logger.request(method, url, meta?)` → nivel `info`, añade `{ request: true, method, url }`.
- `logger.response(method, url, statusCode, meta?)` → `info` o `error` según `statusCode >= 400`.

## 5. Ejemplos de uso

```ts
import logger from '../config/logger.js';

// Inicio de servidor
logger.info('Servidor escuchando', { port: 3000 });

// Request entrante
logger.request('POST', '/api/users', { body: req.body });

// Respuesta satisfactoria
logger.response('POST', '/api/users', 201, { userId: newUser.id });

// Log de error
logger.error('Falló creación de usuario', { error: err });

// Log de éxito
logger.success('Usuario creado con éxito', { userId: newUser.id });
```

## 6. Personalización avanzada

- Cambiar rutas de logs: modificar `combinedLogPath` y `errorLogPath`.
- Añadir nuevos transportes (p.ej., envío a servicios remotos) editando `pinoConfig.transport.targets`.
- Ajustar formato de `pino-pretty` con cualquier opción documentada en la [guía oficial](https://github.com/pinojs/pino-pretty).

---

Para detalles completos consulte el código fuente en `src/config/logger.ts` y la documentación de Pino.
