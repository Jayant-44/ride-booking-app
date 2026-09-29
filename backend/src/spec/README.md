# Especificaciones OpenAPI Modulares

Este directorio contiene las especificaciones OpenAPI organizadas por módulos para una mejor mantenibilidad y organización.

## Estructura de Archivos

```
src/spec/
├── usuarios.json      # Módulo de usuarios externos e internos
├── aplicaciones.json  # Módulo de aplicaciones y roles
├── accesos.json       # Módulo de accesos de usuarios a aplicaciones
├── bundler.js         # Script para combinar módulos
├── openapi.json       # Archivo final generado (no editar manualmente)
└── README.md          # Esta documentación
```

## Módulos

### 1. Usuarios (`usuarios.json`)

Contiene todas las rutas y esquemas relacionados con:

- **Usuarios externos**: Creación, lectura, actualización y eliminación
- **Empleados internos**: Consulta desde base de datos de RH
- **Esquemas**: `UsuarioExterno`, `Empleado`, `CreateUsuarioExternoRequest`, etc.

### 2. Aplicaciones (`aplicaciones.json`)

Contiene todas las rutas y esquemas relacionados con:

- **Aplicaciones**: CRUD completo de aplicaciones
- **Roles de aplicaciones**: Gestión de roles por aplicación
- **Esquemas**: `Aplicacion`, `AplicacionRol`, `CreateAplicacionRequest`, etc.

### 3. Accesos (`accesos.json`)

Contiene todas las rutas y esquemas relacionados con:

- **Accesos**: Creación y consulta de accesos
- **Accesos a aplicaciones**: Asignación y revocación de accesos
- **Esquemas**: `AccesoDetallado`, `CreateAccesoRequest`, `AccesoAplicacionDetallado`, etc.

## Uso del Bundler

### Ejecución Manual

```bash
# Desde la raíz del proyecto
node src/spec/bundler.js
```

### Scripts de NPM/PNPM

```bash
# Construir especificación completa
pnpm spec:build

# Construir y mostrar estadísticas
pnpm spec:bundle
```

### Proceso de Bundling

El bundler realiza las siguientes operaciones:

1. **Validación**: Verifica que todos los módulos existan
2. **Lectura**: Carga cada archivo modular
3. **Combinación**: Fusiona las secciones:
   - `tags`: Elimina duplicados por nombre
   - `paths`: Combina todas las rutas
   - `components.schemas`: Fusiona esquemas (duplicados se mantienen)
   - `components.responses`: Fusiona respuestas comunes
4. **Generación**: Crea `openapi.json` con la especificación completa

## Workflow de Desarrollo

### Para modificar la API:

1. **Edita el módulo correspondiente**:

   - Cambios en usuarios → `usuarios.json`
   - Cambios en aplicaciones → `aplicaciones.json`
   - Cambios en accesos → `accesos.json`

2. **Ejecuta el bundler**:

   ```bash
   pnpm spec:build
   ```

3. **Verifica el resultado**:
   - El archivo `openapi.json` se actualiza automáticamente
   - Revisa las estadísticas en la consola

### ⚠️ Importante

- **NO edites** `openapi.json` directamente
- Siempre modifica los archivos modulares
- Ejecuta el bundler después de cada cambio

## Esquemas Compartidos

Algunos esquemas aparecen en múltiples módulos:

- `ApiResponse`: Respuesta estándar de la API
- `ErrorResponse`: Respuesta de error estándar
- `EmpleadoInfo`: Información básica de empleado
- `UsuarioExternoInfo`: Información básica de usuario externo

El bundler maneja automáticamente estos duplicados manteniendo una sola definición.

## Ventajas de la Arquitectura Modular

### ✅ Mantenibilidad

- Archivos más pequeños y enfocados
- Fácil localización de cambios
- Menos conflictos en control de versiones

### ✅ Escalabilidad

- Fácil agregar nuevos módulos
- Separación clara de responsabilidades
- Desarrollo en paralelo por equipos

### ✅ Reutilización

- Esquemas compartidos centralizados
- Respuestas estándar consistentes
- Patrones comunes reutilizables

### ✅ Testing

- Validación por módulo independiente
- Testing de integración automático
- Detección temprana de inconsistencias

## Troubleshooting

### El bundler no encuentra un módulo

```
❌ Archivos faltantes: modulo.json
```

**Solución**: Verifica que el archivo existe en `src/spec/`

### Error de sintaxis JSON

```
❌ Error leyendo archivo: Unexpected token
```

**Solución**: Valida la sintaxis JSON del módulo con error

### Conflictos de esquemas

El bundler mantiene el primer esquema encontrado en caso de duplicados.
Para resolverlo, asegúrate de que los esquemas compartidos sean idénticos.
