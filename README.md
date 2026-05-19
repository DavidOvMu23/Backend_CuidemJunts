# CuidemJunts — Backend

API REST para la plataforma CuidemJunts, construida con **NestJS** y **PostgreSQL**.  
Se despliega con Docker Compose: un contenedor con la app NestJS y otro con la base de datos.

---

## Tecnologías

| Paquete | Para qué se usa |
|---|---|
| NestJS 11 | Framework backend (controladores, servicios, guards) |
| TypeORM 0.3 | ORM para PostgreSQL (entidades, migraciones) |
| PostgreSQL 16 | Base de datos relacional |
| Passport + JWT | Autenticación con tokens JWT |
| class-validator | Validación de DTOs en cada endpoint |
| bcrypt | Hash de contraseñas |
| @nestjs/swagger | Documentación automática de la API (OpenAPI) |
| Docker + Docker Compose | Contenedores para desarrollo y producción |

---

## Requisitos previos

- **Docker** y **Docker Compose** instalados
- (Opcional para desarrollo sin Docker) Node.js 22+ y PostgreSQL 16+

---

## Puesta en marcha con Docker

```bash
# 1. Entra en la carpeta del backend
cd Backend_CuidemJunts

# 2. Crea el fichero de variables de entorno
cp .env.example .env   # Si no existe .env.example, créalo (ver sección Variables de entorno)

# 3. Arranca los contenedores
docker compose up -d

# 4. Comprueba que todo está en marcha
docker compose logs -f webserver
```

El servidor quedará disponible en `http://localhost:3000` (o el puerto que configures en `WEB_SERVER_PORT`).

### Reconstruir tras cambios en dependencias

```bash
docker compose build --no-cache webserver && docker compose up -d webserver
```

---

## Variables de entorno

Crea un fichero `.env` en la raíz de `Backend_CuidemJunts/` con estas variables:

```env
# Base de datos
DB_HOST=database
DB_PORT=5432
DB_USER=cuidemjunts
DB_PASSWORD=tu_password_seguro
DB_DATABASE=cuidemjunts_db
DB_ROOT_PASSWORD=otro_password_seguro

# Servidor
WEB_SERVER_PORT=3000
NODE_ENV=development
TZ=Europe/Madrid

# JWT
JWT_SECRET=una_clave_secreta_muy_larga_y_aleatoria
JWT_EXPIRATION=8h
```

> Nunca subas el fichero `.env` al repositorio. Ya está en `.gitignore`.

---

## Desarrollo sin Docker

```bash
cd nest_backend
npm install

# Arranca en modo watch (recarga automática al guardar)
npm run start:dev

# Compilar para producción
npm run build
npm run start:prod
```

Necesitarás tener PostgreSQL corriendo localmente y configurar `.env` con `DB_HOST=localhost`.

---

## Estructura del proyecto

```
nest_backend/src/
├── main.ts                  # Punto de entrada (Puerto, ValidationPipe, Swagger)
├── app.module.ts            # Módulo raíz que importa todos los demás
├── auth/                    # Login, JWT, guards de autenticación
├── trabajador/              # Trabajadores (supervisores y teleoperadores) — herencia STI
├── supervisor/              # Módulo específico de supervisores
├── teleoperador/            # Módulo específico de teleoperadores
├── usuario/                 # Usuarios/pacientes atendidos
├── grupo/                   # Grupos de trabajo
├── comunicacion/            # Llamadas y registros de comunicación
├── contacto_emergencia/     # Contactos de emergencia vinculados a usuarios
├── notificacion/            # Notificaciones internas para teleoperadores
├── database/                # Configuración de TypeORM y conexión a PostgreSQL
└── data/                    # Datos de seed para poblar la base de datos inicial
```

### Herencia de entidades (Single Table Inheritance)

`Trabajador` es la entidad base. `Supervisor` y `Teleoperador` heredan de ella y añaden campos propios (DNI para supervisores, NIA y grupo para teleoperadores). Todos comparten la misma tabla en la base de datos.

---

## Endpoints principales

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/auth/login` | Iniciar sesión, devuelve token JWT |
| GET | `/trabajador` | Listar todos los trabajadores |
| POST | `/trabajador` | Crear trabajador (supervisor o teleoperador) |
| PATCH | `/trabajador/:id` | Actualizar trabajador |
| DELETE | `/trabajador/:id` | Eliminar trabajador |
| GET | `/usuario` | Listar pacientes |
| POST | `/usuario` | Crear paciente |
| GET | `/grupo` | Listar grupos |
| POST | `/grupo` | Crear grupo |
| DELETE | `/grupo/:id` | Eliminar grupo |
| GET | `/comunicacion` | Listar llamadas |
| POST | `/comunicacion` | Registrar llamada |
| GET | `/contacto_emergencia` | Listar contactos de emergencia |
| GET | `/notificacion` | Listar notificaciones |

La documentación completa de la API (Swagger) está disponible en `http://localhost:3000/api` cuando el servidor está en marcha.

---

## Validación

Todos los endpoints usan `ValidationPipe` con `whitelist: true` y `forbidNonWhitelisted: true`.  
Esto significa que cualquier campo que no esté declarado en el DTO será rechazado automáticamente con un error 400.

---

## Comandos útiles

```bash
# Ver logs en tiempo real
docker compose logs -f webserver

# Parar los contenedores
docker compose down

# Parar y borrar los datos de la base de datos
docker compose down -v

# Ejecutar tests
cd nest_backend && npm run test
```
