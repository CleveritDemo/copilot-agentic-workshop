# 🧠 ToDo List App - Advanced Technical Documentation

Este repositorio implementa una aplicacion fullstack orientada a escenarios de aprendizaje y pruebas operativas para equipos de desarrollo y plataforma. La solucion expone una API REST con Node.js/Express y una interfaz web statica servida por Nginx, orquestadas mediante Docker Compose. 🚀

---

## 🎯 Publico Objetivo

- 👩‍💻 Developers: implementacion de features CRUD y consumo de API REST.
- 🖥️ Sysadmins: operacion de contenedores, puertos y persistencia local.
- ⚙️ DevOps Engineers: flujo de build/run, troubleshooting y automatizacion.
- ☁️ Cloud Engineers: base para contenerizacion y despliegue en plataformas cloud.

---

## 🧩 Runtimes, Frameworks y Componentes

### Backend API

- Runtime: Node.js 20 (imagen `node:20-alpine` en Docker).
- Framework: Express.js 4.x.
- Librerias principales:
  - `cors` para CORS.
  - `uuid` para identificadores unicos de tareas.
- Persistencia: archivo JSON local (`backend/data/tasks.json`).

### Frontend Web

- Runtime de serving: Nginx Alpine (`nginx:alpine`).
- Stack cliente: HTML5 + CSS3 + Vanilla JavaScript.
- Comunicacion: fetch API hacia `http://localhost:3000/api/tasks`.

### Orquestacion y Contenedores

- Docker Compose para levantar servicios `backend` y `frontend`.
- Red de Compose compartida para comunicacion entre contenedores.
- Volumen bind mount para persistencia de datos del backend:
  - `./backend/data:/app/data`

---

## 🗂️ Estructura Tecnica del Proyecto

```text
copilot-agentic-workshop/
├── backend/
│   ├── controllers/
│   │   └── tasksController.js
│   ├── data/
│   │   └── tasks.json
│   ├── routes/
│   │   └── tasks.js
│   ├── Dockerfile
│   ├── docker-entrypoint.sh
│   ├── index.js
│   └── package.json
├── frontend/
│   ├── Dockerfile
│   ├── index.html
│   ├── script.js
│   └── style.css
├── docker-compose.yml
└── about.md
```

---

## ▶️ Ejecucion Detallada del Proyecto

### 1) Prerrequisitos

- Docker Desktop o Docker Engine + Docker Compose plugin.
- Git CLI.
- Navegador moderno (Edge, Chrome, Firefox, Safari). 🌐

### 2) Clonar repositorio

```bash
git clone https://github.com/CleveritDemo/copilot-agentic-workshop.git
cd copilot-agentic-workshop
```

### 3) Build y arranque de servicios

Comando recomendado (Compose v2):

```bash
docker compose up --build
```

Si deseas correr en background:

```bash
docker compose up --build -d
```

### 4) Verificacion operativa

Inspeccion de estado:

```bash
docker compose ps
```

Ver logs:

```bash
docker compose logs -f backend
docker compose logs -f frontend
```

### 5) Detener servicios

```bash
docker compose down
```

---

## 🌐 Acceso desde Navegador y Endpoints

### Frontend UI

- URL: http://localhost:8080
- Funcion: interfaz de tareas (crear, listar, completar, eliminar).

### Backend API

- Base URL: http://localhost:3000/api/tasks
- Operaciones:
  - `GET /api/tasks` -> listar tareas
  - `POST /api/tasks` -> crear tarea
  - `PUT /api/tasks/:id` -> actualizar tarea
  - `DELETE /api/tasks/:id` -> eliminar tarea

Ejemplo de prueba rapida:

```bash
curl http://localhost:3000/api/tasks
```

---

## 🛠️ Consideraciones Operativas (DevOps/SRE)

- Persistencia: el bind mount de `backend/data` conserva tareas entre reinicios del contenedor.
- Reinicio automatico del backend: `restart: always` en Compose.
- Resolucion de problemas de cache (build):

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

- Nota Compose: la clave `version` en `docker-compose.yml` puede mostrar warning de obsolescencia en Compose v2; no bloquea la ejecucion.

---

## 🔒 Recomendaciones para Entornos Productivos

- Exponer servicios detras de reverse proxy con TLS (Nginx/Traefik/Ingress).
- Incorporar observabilidad: logs estructurados, health checks y metricas.
- Sustituir persistencia en archivo por almacenamiento transaccional (DB gestionada).
- Implementar hardening de imagenes y escaneo de vulnerabilidades en CI/CD.

---

## 📬 Soporte y Evolucion

Para mejoras y nuevas funcionalidades, utilizar Issues del repositorio y mantener trazabilidad tecnica de cambios por feature. ✨
