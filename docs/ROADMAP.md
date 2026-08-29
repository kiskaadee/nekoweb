# Roadmap

> **Goal:** Build a multi-user, self-hosted web service consuming HakuNeko's 1,200+ connectors via a zero-fork dynamic container build, integrated with Traefik, SQLite3 WAL, and homelab media servers.
>
> **Stack:** FastAPI + UV + SQLite3 WAL (Backend) · React + TanStack (Frontend) · Headless Scraper Daemon (Xvfb + Upstream HakuNeko) · Traefik v3 (`appctl`)
> **Non-Goal**: 

---

## 1. Zero-Fork Architecture

```
Browser ──HTTPS──► Traefik v3 (proxy-net) ──► FastAPI Gateway (Single container w/ UI)
                                                     │ (embedded /app/data/nekoweb.db)
                                       ┌─────────────┴─────────────┐
                                  WebSocket RPC               SQLite3 Engine
                                       │                      (aiosqlite WAL)
                                nekoweb-daemon
                                (headless + Xvfb)
                                [Clones upstream
                                 at build time]
```

---

## 2. Phased Implementation Roadmap

### Phase 1: Minimal RPC Bridge Daemon (`daemon/`)
- [ ] Create `daemon/index.js` and `daemon/rpc-server.js` (~150 lines) to bootstrap HakuNeko's engine headlessly inside Electron and expose JSON-RPC on `:9876`.
- [ ] Implement `deploy/Dockerfile.daemon` to clone `manga-download/hakuneko` dynamically during build and run under `xvfb-run`.
- [ ] Validate RPC methods (`ListPlugins`, `FetchMangas`, `FetchChapters`, `FetchPages`) over local WebSocket connection.

### Phase 2: FastAPI Gateway & Database Model (`backend/`)
- [x] Setup `pyproject.toml` with `fastapi`, `uvicorn[standard]`, `sqlalchemy[asyncio]`, `aiosqlite`, `alembic`, `pydantic-settings`, `websockets`.
- [ ] Define database models in `backend/app/db/` (`User`, `Bookmark`, `ReadingProgress`, `DownloadTask`).
- [ ] Setup SQLite connection with WAL pragma (`PRAGMA journal_mode=WAL;`).
- [ ] Implement WebSocket RPC client connecting to `nekoweb-daemon:9876`.
- [ ] Create REST routes (`/api/auth`, `/api/plugins`, `/api/reader/proxy`, `/api/reader/progress`, `/api/downloads`, `/api/bookmarks`).

### Phase 3: Frontend Web Client & Reader (`frontend/`)
- [ ] Scaffold Vite + React + TypeScript + Tailwind CSS application.
- [ ] Implement TanStack Router layout (Catalog, Detail, Reader, Queue, Bookmarks).
- [ ] Build interactive Web Reader supporting Webtoon continuous scroll and dual/single paged modes with automatic reading progress debounce sync.
- [ ] Build download queue and connector browser with TanStack Table.

### Phase 4: Download Engine & CBZ Storage
- [ ] Implement server-side chapter download manager packaging pages into `.cbz` archives.
- [ ] Generate structured `ComicInfo.xml` metadata files for Kavita / Komga / Jellyfin indexing.

### Phase 5: Homelab Deployment & `appctl` Integration
- [ ] Configure `deploy/docker-compose.yml` with `proxy-net` and Traefik v3 labels (`Host("nekoweb.arch-services.mywire.org")`).
- [ ] Add `nekoweb` service mapping in `/home/kiskaadee/Deployments/traefik-deployments/appctl`.
