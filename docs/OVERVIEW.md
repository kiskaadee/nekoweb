# Project Overview: NekoWeb (HakuNeko Homelab Web Platform)

> **A self-hosted, multi-user web reader and scraper platform powered headlessly by HakuNeko's 1,200+ connectors in a modern homelab environment.**

---

## 1. Vision & Executive Summary

**NekoWeb** brings HakuNeko's extensive library of 1,200+ scrapers directly into the browser as a 24/7 homelab web application. 

The objective is to remove the need for installing desktop client applications on multiple user devices by providing:

1. **A Modern, Responsive Web Application** built with: React, TanStack (Router + Query + Table), and Tailwind CSS for seamless browsing, reading, and bookmarking across desktop, tablet, and mobile devices.
2. **A robust FastAPI backend** serving as the API gateway, event hub, and media orchestrator.
3. **Multi-User State & Progress Tracking** backed by an embedded SQLite3 database (`aiosqlite` + `SQLAlchemy 2.0` in WAL mode) with zero external database dependencies.
4. **Zero-Fork upstream integration:** Connectors are dynamically cloned from upstream HakuNeko at Docker build time, keeping scrapers evergreen without maintaining a repository fork.
5. **CBZ / ComicInfo.xml download pipeline** formatting saved media for direct ingestion by Kavita, Komga, and Jellyfin.
6. **Homelab-native deployment** integrating into an existing [Traefik v3 reverse proxy](https://github.com/kiskaadee/traefik-homelab) and [`appctl` CLI infrastructure](https://github.com/kiskaadee/traefik-deployments).

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
                        │   │  └── HN's Connectors  │                             │
                        │   └───────────┬───────────┘                             │
                        │               │ Downloads                               │
                        │               ▼ (CBZ + ComicInfo)                       │
                        │       /srv/manga-storage/ ──► [Kavita / Komga / Jellyfin]│
                        └─────────────────────────────────────────────────────────┘
```

---

## 2. Zero-Fork Upstream Integration Strategy

Instead of cloning and forking the HakuNeko codebase into this repository:

- **Our Repo:** Contains only custom web code (`backend/`, `frontend/`, `daemon/` bridge script, `deploy/`, `docs/`).
- **Dynamic Engine Assembly:** The scraper daemon Dockerfile (`deploy/Dockerfile.daemon`) clones upstream `github:manga-download/hakuneko` during container build and mounts our minimal WebSocket RPC bootstrap bridge on top of it.
- **Evergreen Scrapers:** Upstream bugfixes and new connector releases from Hakuneko's repository are pulled automatically whenever the container image is rebuilt.

---

## 3. Media Consumption & Reading Architecture

The platform aims to provide support for both **ad-hoc streaming** and **persistent library archiving**:

```
                      ┌────────────────────────────────────────┐
                      │        User Action in Web UI           │
                      └──────────────────┬─────────────────────┘
                                         │
                    ┌────────────────────┴───────────────────┐
                    ▼                                        ▼
         [Stream & Read Online]                    [Download for Library]
                    │                                         │
                    ▼                                         ▼
           Built-in Web Reader                       CBZ Download Manager
    - Continuous vertical scroll (Webtoon)    - High-speed async page downloads
    - Paged single / dual-page mode (future)  - ComicInfo.xml metadata generation
    - Image proxying with caching headers     - Organized for Kavita / Komga / Jellyfin
    - Automatic reading progress sync         - Real-time WS progress notifications
```



---

## 4. Planned Repository Structure

```
nekoweb/
├── backend/                    # FastAPI + UV API Gateway
│   ├── app/
│   │   ├── main.py             # FastAPI entrypoint & static mount
│   │   ├── config.py           # Pydantic Settings
│   │   ├── db/                 # SQLAlchemy models & database session
│   │   ├── rpc/                # WebSocket client connecting to Daemon
│   │   ├── routers/            # API routes (auth, plugins, reader, downloads, bookmarks)
│   │   └── ws/                 # Real-time WebSocket event broadcaster
│   ├── migrations/             # Alembic database migrations
│   ├── pyproject.toml          # UV project configuration
│   └── uv.lock                 # UV frozen lockfile
├── frontend/                   # React + TanStack Web Application
│   ├── src/
│   │   ├── routes/             # TanStack Router route definitions
│   │   ├── components/         # UI components (Reader, QueueTable, MangaGrid)
│   │   ├── hooks/              # Custom TanStack Query & WebSocket hooks
│   │   └── lib/                # API client & types
│   ├── package.json
│   └── vite.config.ts
├── daemon/                     # Minimal Node/Electron RPC Bridge Script (~150 lines)
│   ├── index.js                # Boots Electron headlessly & loads HakuNeko engine
│   └── rpc-server.js           # JSON-RPC WebSocket server on :9876
├── deploy/                     # Homelab deployment manifests
│   ├── docker-compose.yml      # Traefik-ready compose definition
│   ├── Dockerfile.daemon       # Clones upstream HakuNeko + Xvfb runtime
│   └── Dockerfile.backend      # Multi-stage FastAPI + Frontend image
└── docs/                       # Architecture, ADRs, and guides
    ├── adr/                    # Architecture Decision Records
    ├── ROADMAP.md              # Phased execution roadmap
    └── OVERVIEW.md             # This document
```

---

## 5. Homelab & `appctl` Integration

To deploy alongside existing services in [Deployments](https://github.com/kiskaadee/traefik-deployments):

1. `nekoweb` is managed via standard `appctl` commands (`appctl up nekoweb`, `appctl logs nekoweb`).
2. Configured with runtime secrets from `sops-nix` (`/run/secrets/rendered/traefik-deployments.env`).
3. Attaches to `proxy-net` and routes through Traefik v3 wildcard TLS (`Host("nekoweb.arch-services.mywire.org")`).
