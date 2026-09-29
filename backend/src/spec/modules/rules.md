# Reglas para Documentación OpenAPI

## 📋 Índice

1. [Formato de Respuestas Estándar](#formato-de-respuestas-estándar)
2. [Estructura de Schemas de Respuesta](#estructura-de-schemas-de-respuesta)
3. [Componentes Reutilizables Obligatorios](#componentes-reutilizables-obligatorios)
4. [Respuestas de Error Estándar](#respuestas-de-error-estándar)
5. [Códigos de Estado HTTP](#códigos-de-estado-http)
6. [Plantilla de Respuestas por Tipo](#plantilla-de-respuestas-por-tipo)
7. [Ejemplos Completos](#ejemplos-completos)

---

## 1. Formato de Respuestas Estándar

### Respuestas Exitosas (200-299)

Todos los endpoints exitosos **DEBEN** devolver una respuesta que cumpla con esta estructura:

```typescript
{
  success: boolean;        // OBLIGATORIO: true
  message: string;         // OBLIGATORIO: Descripción legible del resultado
  data?: T | T[];         // OPCIONAL: Datos de retorno (objeto o array)
  resultsCount?: number;  // AUTOMÁTICO: Solo cuando data es un array
}
```

**Ejemplos:**

```json
// Respuesta con objeto único
{
  "success": true,
  "message": "Usuario creado exitosamente",
  "data": {
    "id": "clv1234567890",
    "firstName": "Juan",
    "email": "juan@example.com"
  }
}

// Respuesta con array (incluye resultsCount automáticamente)
{
  "success": true,
  "message": "Usuarios obtenidos exitosamente",
  "data": [
    { "id": "clv123", "firstName": "Juan" },
    { "id": "clv456", "firstName": "María" }
  ],
  "resultsCount": 2
}

// Respuesta sin data (solo confirmación)
{
  "success": true,
  "message": "Operación completada exitosamente"
}
```

### Respuestas de Error (400-599)

Todos los endpoints con error **DEBEN** devolver:

```typescript
{
  success: boolean;   // OBLIGATORIO: false
  message: string;    // OBLIGATORIO: Mensaje de error descriptivo
  stack?: string;     // OPCIONAL: Solo en desarrollo, null en producción
}
```

**Ejemplo:**

```json
{
	"success": false,
	"message": "El correo electrónico ya está en uso"
}
```

---

## 2. Estructura de Schemas de Respuesta

### Para Respuestas con Objeto Único

Usar `allOf` para combinar `ApiResponse` base con el schema específico:

```json
{
	"responses": {
		"200": {
			"description": "Usuario creado exitosamente",
			"content": {
				"application/json": {
					"schema": {
						"allOf": [
							{
								"$ref": "#/components/schemas/ApiResponse"
							},
							{
								"type": "object",
								"properties": {
									"data": {
										"$ref": "#/components/schemas/User"
									}
								}
							}
						]
					}
				}
			}
		}
	}
}
```

### Para Respuestas con Array

Usar `allOf` con `type: "array"` y `resultsCount`:

```json
{
	"responses": {
		"200": {
			"description": "Lista de usuarios obtenida exitosamente",
			"content": {
				"application/json": {
					"schema": {
						"allOf": [
							{
								"$ref": "#/components/schemas/ApiResponse"
							},
							{
								"type": "object",
								"properties": {
									"data": {
										"type": "array",
										"items": {
											"$ref": "#/components/schemas/User"
										}
									},
									"resultsCount": {
										"type": "integer",
										"description": "Número total de elementos en el array",
										"example": 10
									}
								}
							}
						]
					}
				}
			}
		}
	}
}
```

### Para Respuestas Sin Data (Solo Confirmación)

Solo usar `ApiResponse` sin extensión:

```json
{
	"responses": {
		"200": {
			"description": "Operación completada",
			"content": {
				"application/json": {
					"schema": {
						"$ref": "#/components/schemas/ApiResponse"
					}
				}
			}
		}
	}
}
```

---

## 3. Componentes Reutilizables Obligatorios

Cada archivo OpenAPI de módulo **DEBE** incluir estos componentes en `components.schemas`:

### ApiResponse (Base para Respuestas Exitosas)

```json
{
	"ApiResponse": {
		"type": "object",
		"required": ["success", "message"],
		"properties": {
			"success": {
				"type": "boolean",
				"description": "Indica si la operación fue exitosa",
				"example": true
			},
			"message": {
				"type": "string",
				"description": "Mensaje descriptivo del resultado",
				"example": "Operación completada exitosamente"
			}
		}
	}
}
```

### ErrorResponse (Base para Respuestas de Error)

```json
{
	"ErrorResponse": {
		"type": "object",
		"required": ["success", "message"],
		"properties": {
			"success": {
				"type": "boolean",
				"description": "Indica si la operación fue exitosa",
				"example": false
			},
			"message": {
				"type": "string",
				"description": "Mensaje de error descriptivo",
				"example": "Error en la validación de datos"
			},
			"stack": {
				"type": "string",
				"nullable": true,
				"description": "Stack trace del error (solo en desarrollo)",
				"example": null
			}
		}
	}
}
```

---

## 4. Respuestas de Error Estándar

Cada archivo OpenAPI **DEBE** incluir estas respuestas reutilizables en `components.responses`:

```json
{
	"responses": {
		"BadRequest": {
			"description": "Error de validación o parámetros incorrectos",
			"content": {
				"application/json": {
					"schema": {
						"$ref": "#/components/schemas/ErrorResponse"
					},
					"example": {
						"success": false,
						"message": "El campo 'email' es requerido"
					}
				}
			}
		},
		"Unauthorized": {
			"description": "No autorizado - Token inválido o ausente",
			"content": {
				"application/json": {
					"schema": {
						"$ref": "#/components/schemas/ErrorResponse"
					},
					"example": {
						"success": false,
						"message": "Token de autenticación inválido"
					}
				}
			}
		},
		"Forbidden": {
			"description": "Prohibido - Sin permisos suficientes",
			"content": {
				"application/json": {
					"schema": {
						"$ref": "#/components/schemas/ErrorResponse"
					},
					"example": {
						"success": false,
						"message": "No tienes permisos para realizar esta acción"
					}
				}
			}
		},
		"NotFound": {
			"description": "Recurso no encontrado",
			"content": {
				"application/json": {
					"schema": {
						"$ref": "#/components/schemas/ErrorResponse"
					},
					"example": {
						"success": false,
						"message": "Usuario no encontrado"
					}
				}
			}
		},
		"Conflict": {
			"description": "Conflicto - Recurso ya existe",
			"content": {
				"application/json": {
					"schema": {
						"$ref": "#/components/schemas/ErrorResponse"
					},
					"example": {
						"success": false,
						"message": "El correo electrónico ya está en uso"
					}
				}
			}
		},
		"InternalServerError": {
			"description": "Error interno del servidor",
			"content": {
				"application/json": {
					"schema": {
						"$ref": "#/components/schemas/ErrorResponse"
					},
					"example": {
						"success": false,
						"message": "Error interno del servidor"
					}
				}
			}
		}
	}
}
```

---

## 5. Códigos de Estado HTTP

### Matriz de Códigos por Operación

| Operación                  | Éxito | Errores Comunes     |
| -------------------------- | ----- | ------------------- |
| **POST** (Crear)           | `200` | `400`, `409`, `500` |
| **GET** (Obtener)          | `200` | `404`, `500`        |
| **GET** (Listar)           | `200` | `500`               |
| **PUT/PATCH** (Actualizar) | `200` | `400`, `404`, `500` |
| **DELETE** (Eliminar)      | `200` | `400`, `404`, `500` |

### Uso de Códigos HTTP

- **200 OK**: Operación exitosa (usar para todas las operaciones exitosas, incluyendo POST)
- **400 Bad Request**: Validación fallida, parámetros incorrectos
- **401 Unauthorized**: Token inválido o ausente
- **403 Forbidden**: Sin permisos suficientes
- **404 Not Found**: Recurso no encontrado
- **409 Conflict**: Conflicto de recursos (ej: email duplicado)
- **500 Internal Server Error**: Error del servidor

---

## 6. Plantilla de Respuestas por Tipo

### POST - Crear Recurso

```json
{
	"responses": {
		"200": {
			"description": "[Recurso] creado exitosamente",
			"content": {
				"application/json": {
					"schema": {
						"allOf": [
							{ "$ref": "#/components/schemas/ApiResponse" },
							{
								"type": "object",
								"properties": {
									"data": { "$ref": "#/components/schemas/[Recurso]" }
								}
							}
						]
					}
				}
			}
		},
		"400": { "$ref": "#/components/responses/BadRequest" },
		"409": { "$ref": "#/components/responses/Conflict" },
		"500": { "$ref": "#/components/responses/InternalServerError" }
	}
}
```

### GET - Obtener Recurso Individual

```json
{
	"responses": {
		"200": {
			"description": "[Recurso] obtenido exitosamente",
			"content": {
				"application/json": {
					"schema": {
						"allOf": [
							{ "$ref": "#/components/schemas/ApiResponse" },
							{
								"type": "object",
								"properties": {
									"data": { "$ref": "#/components/schemas/[Recurso]" }
								}
							}
						]
					}
				}
			}
		},
		"404": { "$ref": "#/components/responses/NotFound" },
		"500": { "$ref": "#/components/responses/InternalServerError" }
	}
}
```

### GET - Listar Recursos

```json
{
	"responses": {
		"200": {
			"description": "Lista de [recursos] obtenida exitosamente",
			"content": {
				"application/json": {
					"schema": {
						"allOf": [
							{ "$ref": "#/components/schemas/ApiResponse" },
							{
								"type": "object",
								"properties": {
									"data": {
										"type": "array",
										"items": { "$ref": "#/components/schemas/[Recurso]" }
									},
									"resultsCount": {
										"type": "integer",
										"example": 10
									}
								}
							}
						]
					}
				}
			}
		},
		"500": { "$ref": "#/components/responses/InternalServerError" }
	}
}
```

### PUT/PATCH - Actualizar Recurso

```json
{
	"responses": {
		"200": {
			"description": "[Recurso] actualizado exitosamente",
			"content": {
				"application/json": {
					"schema": {
						"allOf": [
							{ "$ref": "#/components/schemas/ApiResponse" },
							{
								"type": "object",
								"properties": {
									"data": { "$ref": "#/components/schemas/[Recurso]" }
								}
							}
						]
					}
				}
			}
		},
		"400": { "$ref": "#/components/responses/BadRequest" },
		"404": { "$ref": "#/components/responses/NotFound" },
		"500": { "$ref": "#/components/responses/InternalServerError" }
	}
}
```

### DELETE - Eliminar Recurso

```json
{
	"responses": {
		"200": {
			"description": "[Recurso] eliminado exitosamente",
			"content": {
				"application/json": {
					"schema": {
						"allOf": [
							{ "$ref": "#/components/schemas/ApiResponse" },
							{
								"type": "object",
								"properties": {
									"data": { "$ref": "#/components/schemas/[Recurso]" }
								}
							}
						]
					}
				}
			}
		},
		"400": { "$ref": "#/components/responses/BadRequest" },
		"404": { "$ref": "#/components/responses/NotFound" },
		"500": { "$ref": "#/components/responses/InternalServerError" }
	}
}
```

---

## 7. Ejemplos Completos

### Ejemplo Completo: Endpoint POST /users

```json
{
	"paths": {
		"/users": {
			"post": {
				"tags": ["Users"],
				"summary": "Crear usuario",
				"description": "Crea un nuevo usuario en el sistema",
				"requestBody": {
					"required": true,
					"content": {
						"application/json": {
							"schema": {
								"$ref": "#/components/schemas/CreateUserRequest"
							}
						}
					}
				},
				"responses": {
					"200": {
						"description": "Usuario creado exitosamente",
						"content": {
							"application/json": {
								"schema": {
									"allOf": [
										{ "$ref": "#/components/schemas/ApiResponse" },
										{
											"type": "object",
											"properties": {
												"data": {
													"$ref": "#/components/schemas/User"
												}
											}
										}
									]
								},
								"example": {
									"success": true,
									"message": "Usuario creado exitosamente",
									"data": {
										"id": "clv1234567890",
										"firstName": "Juan",
										"lastName": "Pérez",
										"email": "juan.perez@example.com",
										"companyId": "cld123456789",
										"createdAt": "2026-02-05T10:30:00Z",
										"updatedAt": "2026-02-05T10:30:00Z"
									}
								}
							}
						}
					},
					"400": { "$ref": "#/components/responses/BadRequest" },
					"409": { "$ref": "#/components/responses/Conflict" },
					"500": { "$ref": "#/components/responses/InternalServerError" }
				}
			}
		}
	}
}
```

### Ejemplo Completo: Endpoint GET /users

```json
{
	"paths": {
		"/users": {
			"get": {
				"tags": ["Users"],
				"summary": "Obtener todos los usuarios",
				"description": "Retorna una lista de todos los usuarios registrados",
				"responses": {
					"200": {
						"description": "Lista de usuarios obtenida exitosamente",
						"content": {
							"application/json": {
								"schema": {
									"allOf": [
										{ "$ref": "#/components/schemas/ApiResponse" },
										{
											"type": "object",
											"properties": {
												"data": {
													"type": "array",
													"items": {
														"$ref": "#/components/schemas/User"
													}
												},
												"resultsCount": {
													"type": "integer",
													"description": "Número total de usuarios",
													"example": 2
												}
											}
										}
									]
								},
								"example": {
									"success": true,
									"message": "Usuarios obtenidos exitosamente",
									"data": [
										{
											"id": "clv123",
											"firstName": "Juan",
											"email": "juan@example.com"
										},
										{
											"id": "clv456",
											"firstName": "María",
											"email": "maria@example.com"
										}
									],
									"resultsCount": 2
								}
							}
						}
					},
					"500": { "$ref": "#/components/responses/InternalServerError" }
				}
			}
		}
	}
}
```

---

## ✅ Checklist de Validación

Al crear o revisar un archivo OpenAPI, verifica:

- [ ] Todos los endpoints exitosos usan `allOf` con `ApiResponse`
- [ ] Los endpoints que retornan arrays incluyen `resultsCount`
- [ ] Todos los errores usan referencias a componentes estándar
- [ ] Se incluyen los schemas `ApiResponse` y `ErrorResponse`
- [ ] Se incluyen todas las respuestas de error estándar
- [ ] Los códigos HTTP son apropiados para cada operación
- [ ] Todos los schemas tienen `description` y `example`
- [ ] Los mensajes de error son descriptivos y en español
- [ ] Las respuestas incluyen ejemplos completos
