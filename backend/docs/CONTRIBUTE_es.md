# Guía de Contribución

## Estándar de Commits (Commitlint + Husky)

El proyecto aplica el estándar **Conventional Commits** para asegurar un historial consistente y permitir automatizaciones (versionado semántico, changelogs, etc.).

### Formato Básico

```
tipo(opcional-alcance): descripción breve en minúsculas

Cuerpo opcional (motivo, contexto)

Footer opcional (BREAKING CHANGE, referencias a issues)
```

### Tipos Permitidos

`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `build`, `revert`

### Reglas Principales Enforzadas

- Tipo obligatorio y en minúsculas
- Scope (si se usa) en minúsculas
- Asunto sin punto final y no vacío
- Longitud máxima del encabezado: 72 caracteres
- Línea en blanco antes de cuerpo / footer si existen

### Ejemplos Válidos

```
feat(auth): agregar endpoint de refresco de tokens
fix(logger): corregir serialización circular en objetos de error
refactor(router): simplificar registro dinámico de rutas
docs: actualizar pasos de despliegue en README
perf(db): reducir N+1 queries en listado de usuarios
```

### Hook Automático

Se usa **Husky** para ejecutar `commitlint` en el hook `commit-msg`. Si el mensaje no cumple reglas, el commit se bloquea.

- Archivo de config: `commitlint.config.js`
- Hook: `.husky/commit-msg`
- Contenido del hook:

```
npx --no -- commitlint --edit $1
```

### Uso Manual (Opcional)

Validar el último commit (después de hacer un commit en amend / rebase):

```bash
pnpm run commitlint
```

### Instalación / Setup (ya incluido)

Si clonas el repo y las dependencias no están instaladas aún:

```bash
pnpm install
```

El script `prepare` activa Husky automáticamente (`husky install`).

### Convenciones para Breaking Changes

Usar el footer:

```
feat(api): unificar endpoints de usuarios

BREAKING CHANGE: se elimina /v1/users/list, usar /v1/users
```

### Buenas Prácticas

- Usa `feat!:` o agrega `BREAKING CHANGE:` cuando rompas compatibilidad
- Prefiere scopes específicos: `auth`, `user`, `db`, `config`, `logger`
- Commits pequeños y atómicos
- Evita mezclar refactors con nuevas features

---

Conventional Commits mejora la trazabilidad y facilita automatizaciones futuras (release notes, versionado semántico, etc.).
