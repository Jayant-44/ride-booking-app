# Plantilla Node.js + Express + TypeScript

Plantilla moderna lista para producción con mejores prácticas de desarrollo.

## ✨ Stack

- **Node.js** + **Express** + **TypeScript** con ESModules
- **Prisma ORM** con PostgreSQL y tipos Zod integrados
- **Swagger/OpenAPI** para documentación automática
- **Pino** para logging estructurado con rotación
- **Zod** para validación de esquemas y variables de entorno
- **Docker** + **Nginx** para despliegue

## 🚀 Inicio Rápido

### Prerequisitos

- Node.js 18+
- pnpm/npm
- PostgreSQL

### Instalación

```bash
git clone https://github.com/juniorodrigo/node-ts.git
cd node-ts
pnpm install
```

### Configuración

1. **Variables de entorno:**

```env
PORT=3000
NODE_ENV=development
DATABASE_URL="postgresql://user:password@localhost:5432/database"
ALLOWED_ORIGINS=http://localhost:3000
```

2. **Base de datos:**

```bash
pnpm run prisma:generate
pnpm run prisma:migrate
```

3. **Desarrollo:**

```bash
pnpm run dev
```

> Servidor disponible en `http://localhost:3000`  
> Documentación de API en `http://localhost:3000/api-docs`

## 📜 Scripts

| Comando             | Descripción               |
| ------------------- | ------------------------- |
| `pnpm run dev`      | Desarrollo con hot reload |
| `pnpm run build`    | Compilar TypeScript       |
| `pnpm run start`    | Producción                |
| `pnpm run test`     | Ejecutar tests            |
| `pnpm run lint`     | Linting                   |
| `pnpm run prisma:*` | Comandos de Prisma        |

## 📁 Estructura

```
src/
├── config/          # Configuración (env, logger, swagger)
├── lib/             # Clientes y utilidades (Prisma, Zod)
├── middlewares/     # Middlewares personalizados
├── modules/         # Módulos de negocio
│   └── test/        # Ejemplo: controller, service, schemas, router
├── spec/            # Documentación OpenAPI
├── types/           # Tipos de TypeScript
├── utils/           # Utilidades generales
├── index.ts         # Punto de entrada
└── routes.ts        # Configuración principal de rutas
```

## 🏗️ Arquitectura de Módulos

Cada módulo sigue el patrón:

```
modules/mi-modulo/
├── controller.ts    # Manejo HTTP
├── service.ts       # Lógica de negocio
├── schemas.ts       # Validación Zod
└── router.ts        # Definición de rutas
```

**Ejemplo de implementación:**

```typescript
// schemas.ts
export const CreateUserSchema = z.object({
	name: z.string().min(2),
	email: z.string().email(),
});

// controller.ts
export async function createUser(req: Request, res: Response) {
	const validation = customParse(CreateUserSchema, req.body);
	if (!validation.success) throw new ValidationError(validation.message);

	const result = await UserService.createUser(validation.data);
	res.success(result.data, result.message);
}
```

## 📝 Características Principales

### Logging con Pino

- Logs estructurados con rotación diaria
- Separación por niveles (error, combined)
- Métodos personalizados: `logger.success()`, `logger.request()`, `logger.response()`
- Ver [docs/LOGGING_es.md](docs/LOGGING_es.md) para más detalles sobre logging.

### Seguridad

- Rate limiting (100 req/15min)
- CORS configurado
- Helmet para cabeceras HTTP
- Compresión inteligente

### Validación

- Esquemas Zod con mensajes amigables
- Validación automática de variables de entorno
- Tipos TypeScript auto-generados

## 🐳 Docker

```bash
# Construir
docker build -f docker/Dockerfile -t mi-app .

# Ejecutar
docker run -p 3000:3000 --env-file .env mi-app
```

## 🤝 Contribuir

Ver [CONTRIBUTE_es.md](./CONTRIBUTE_es.md) para guías de desarrollo y estándares de commits.

## 📄 Licencia

Licencia MIT
