# System Architecture & Component Contracts

> **Authoritative reference for NekoWeb's component topology, service boundaries, and communication contracts.**

---

## 1. System Topology

```
                        ┌─────────────────────────────────────────────────────────┐
                        │                   HOMELAB SERVER                        │
                        │                                                         │
   User (Browser) ──────┼──► Traefik v3 (Wildcard HTTPS + Authelia SSO)          │
   [Desktop / Mobile]   │        │                                                │
                        │        ▼ (:8000) [proxy-net]                            │
                        │   ┌─────────────────────────────────────────────────┐   │
                        │   │ nekoweb-backend (FastAPI + UV + SQLite3 WAL)    │   │
                        │   │  ├── REST API (/api/*)                          │   │
                        │   │  ├── WebSocket Hub (/ws/events)                 │   │
                        │   │  ├── Static UI Server (React + TanStack SPA)    │   │
                        │   │  ├── Chapter Image Streaming / Caching Proxy    │   │
                        │   │  └── Embedded DB: /app/data/nekoweb.db          │   │
                        │   └───┬─────────────────────────────────────────────┘   │
                        │       │ WS RPC (:9876)                                  │
                        │       ▼ [nekoweb-internal]                              │
                        │   ┌───────────────────────┐                             │
                        │   │ nekoweb-daemon        │                             │
                        │   │ (Headless Xvfb +      │                             │
                        │   │  HakuNeko Engine)     │                             │
                        │   │  └── 1,200+ Connectors│                             │
                        │   └───────────┬───────────┘                             │
                        │               │ Downloads                               │
                        │               ▼ (CBZ + ComicInfo)                       │
                        │       /srv/manga-storage/ ──► [Kavita / Komga / Jellyfin]│
                        └─────────────────────────────────────────────────────────┘
```

---

## 2. Component Boundaries & Responsibilities

### 2.1 Backend (`backend/`)
**Role:** Central API gateway, application state, and orchestration.
- **REST API:** Handles authentication, bookmarks, reading progress sync, and download queue operations.
- **Image Proxy:** Proxies external chapter page images via `/api/reader/proxy` with HTTP caching headers to bypass client-side CORS and hotlinking blocks.
- **Persistence:** SQLite3 running in WAL mode with foreign keys enabled, accessed asynchronously via `aiosqlite` and `SQLAlchemy 2.0`. Migrations are managed with Alembic.
- **RPC Client:** Maintains a persistent WebSocket connection to the scraper daemon (`ws://nekoweb-daemon:9876`) with automatic request-response correlation.
- **Static Assets:** Serves the compiled React SPA bundle at `/`.

*Boundary Constraint:* Do not place frontend presentation concerns in the backend beyond serving the static SPA.

---

### 2.2 Frontend (`frontend/`)
**Role:** User interface and client-side presentation.
- **Routing & State:** Built with React, Vite, TanStack Router, TanStack Query, and Tailwind CSS.
- **Interactive Reader:** Supports both continuous vertical scroll (Webtoon mode) and paged layouts (single/double page, LTR/RTL) with debounced reading progress sync to the backend.
- **Catalog & Queue:** Filterable connector browser and live download queue monitoring via WebSocket events (`/ws/events`).

*Boundary Constraint:* Do not duplicate backend business rules or direct scraper calls in the frontend. All interactions flow through the Backend REST/WS API.

---

### 2.3 Daemon (`daemon/`)
**Role:** Headless scraper execution engine.
- **Runtime:** Minimal Node/Electron bootstrap script running inside a container under `xvfb-run` (virtual display).
- **Engine:** Clones and boots upstream HakuNeko (`manga-download/hakuneko`) at build time to execute 1,200+ scrapers and anti-bot challenge scripts (`FetchWindowScript`).
- **RPC Server:** Exposes a JSON-RPC 2.0 WebSocket server listening strictly on private container port `:9876`.

*Boundary Constraint:* Do not move application persistence, user management, or direct client access into the daemon.

---

## 3. Communication Contracts

### 3.1 Client ↔ Backend (HTTP REST & WebSocket)
- `POST /api/auth/login`, `POST /api/auth/register`: Authentication sessions.
- `GET /api/plugins`: List available connectors.
- `GET /api/plugins/{id}/mangas`: List/search manga from a connector.
- `GET /api/plugins/{id}/chapters`: Retrieve chapter list for a manga.
- `GET /api/plugins/{id}/pages`: Retrieve page URLs for a chapter.
- `GET /api/reader/proxy`: Stream chapter page image with cache headers.
- `GET/POST /api/reader/progress`: Track reading state per user.
- `GET/POST/DELETE /api/downloads`: Manage background download queue.
- `GET/POST/DELETE /api/bookmarks`: User bookmark management.
- `WS /ws/events`: Real-time download progress and status fan-out.

### 3.2 Backend ↔ Daemon (WebSocket JSON-RPC on `:9876`)
- `getConnectors()`: Returns `ConnectorSummary[]`.
- `updateConnector(connectorId)`: Triggers catalog refresh.
- `getMangas(connectorId)`: Returns cached `MangaSummary[]`.
- `searchManga(connectorId, query)`: Returns matching `MangaSummary[]`.
- `getMangaFromURI(uri)`: Resolves a manga series from URL.
- `getChapters(connectorId, mangaId)`: Returns `ChapterSummary[]`.
- `getPages(connectorId, mangaId, chapterId)`: Returns `PageInfo[]`.
