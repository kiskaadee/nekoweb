# NekoWeb

> A self-hosted, multi-user web manga reader and scraper platform powered headlessly by
> [HakuNeko](https://github.com/manga-download/hakuneko)'s 1,200+ connectors — designed for homelab deployment.

**Status:** 🚧 Early development — foundation and documentation phase complete, implementation in progress.

---

## What is this?

NekoWeb brings HakuNeko's extensive scraper library into the browser as a 24/7 homelab web service.
Instead of installing a desktop client on every device, all scraping runs in a headless containerised
daemon and is accessible from any browser on the local network.

Key capabilities (planned):
- **Stream & read** manga directly in the browser — continuous Webtoon scroll and paged reader modes.
- **Download to library** — chapters archived as `.cbz` with embedded `ComicInfo.xml` for instant
  discovery by [Kavita](https://www.kavitareader.com/), [Komga](https://komga.org/), and [Jellyfin](https://jellyfin.org/).
- **Multi-user** reading progress, bookmarks, and download queues backed by an embedded SQLite3 database.
- **Evergreen connectors** — upstream HakuNeko is cloned at container build time; no fork to maintain.

---

## Architecture

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
                        │       │ WS RPC (:9876) [nekoweb-internal]               │
                        │       ▼                                                 │
                        │   ┌───────────────────────┐                             │
                        │   │ nekoweb-daemon        │                             │
                        │   │ (Headless Xvfb +      │                             │
                        │   │  HakuNeko Engine)     │                             │
                        │   │  └── 1,200+ Connectors│                             │
                        │   └───────────┬───────────┘                             │
                        │               │ Downloads (CBZ + ComicInfo.xml)         │
                        │               ▼                                         │
                        │       /srv/manga-storage/ ──► [Kavita / Komga / Jellyfin]│
                        └─────────────────────────────────────────────────────────┘
```

---

## Stack

| Layer | Technology |
| :--- | :--- |
| **API Gateway** | Python 3.12 · FastAPI · Uvicorn · `uv` |
| **Persistence** | SQLite3 WAL · SQLAlchemy 2.0 async · aiosqlite · Alembic |
| **Frontend** | React · Vite · TanStack Router / Query / Table · Tailwind CSS |
| **Scraper Daemon** | Node · Electron (headless) · Xvfb · HakuNeko (upstream, zero-fork) |
| **Deployment** | Docker Compose · Traefik v3 · `appctl` · sops-nix secrets |

---

## Project Status

| Phase | Description | Status |
| :--- | :--- | :--- |
| **Foundation** | Nix devShell, `uv` backend scaffold, documentation & ADRs | ✅ Done |
| **Phase 1** | Headless daemon RPC bridge (`daemon/`) + `Dockerfile.daemon` | 🚧 Next |
| **Phase 2** | FastAPI gateway, SQLite3 models, Alembic migrations, RPC client | ⏳ Pending |
| **Phase 3** | React frontend — Vite scaffold, TanStack Router, Web Reader | ⏳ Pending |
| **Phase 4** | Download engine — CBZ packaging, `ComicInfo.xml` generation | ⏳ Pending |
| **Phase 5** | Homelab deployment — Traefik labels, `appctl` integration | ⏳ Pending |

---

## Documentation

| Document | Description |
| :--- | :--- |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Component boundaries, communication contracts, and topology |
| [`docs/OVERVIEW.md`](docs/OVERVIEW.md) | Vision, planned structure, and homelab integration summary |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Phased implementation checklist |
| [`docs/adr/0001`](docs/adr/0001-two-tier-headless-engine-xvfb.md) | Two-tier headless engine with Xvfb |
| [`docs/adr/0002`](docs/adr/0002-fastapi-uv-api-gateway.md) | FastAPI + UV API gateway |
| [`docs/adr/0003`](docs/adr/0003-sqlite3-multi-user-persistence.md) | SQLite3 WAL multi-user persistence |
| [`docs/adr/0004`](docs/adr/0004-web-reader-and-cbz-storage-layout.md) | Web reader and CBZ storage layout |
| [`docs/adr/0005`](docs/adr/0005-traefik-and-appctl-deployment.md) | Traefik v3 and `appctl` homelab deployment |
| [`docs/adr/0006`](docs/adr/0006-zero-fork-upstream-integration.md) | Zero-fork upstream HakuNeko integration |

---

## Development

> 🚧 Setup and usage instructions will be added once Phase 1 is complete.

This project uses [Nix](https://nixos.org/) + [direnv](https://direnv.net/) for reproducible development environments,
and [`uv`](https://github.com/astral-sh/uv) for Python dependency management.

---

## License

[MIT](LICENSE)
