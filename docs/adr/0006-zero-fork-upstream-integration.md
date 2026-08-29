# ADR 0006: Zero-Fork Upstream Integration via Dynamic Container Build

## Status
Accepted

## Context
Upstream HakuNeko (`manga-download/hakuneko`) actively maintains over 1,200 manga, comic, and anime scraping connectors. Forking the repository to add web APIs or running a modified fork would introduce significant maintenance burden, merge conflicts, and stale connectors.

We need a strategy that consumes upstream connectors at their latest releases or pinned commits without polluting our application repository with upstream source code.

## Decision
1. **No Source Forking:** Our repository contains only our custom application code:
   - `backend/`: FastAPI Gateway, Auth, SQLite3 WAL persistence, and Image Proxy.
   - `frontend/`: React + TanStack Web Reader and Management UI.
   - `daemon/`: A minimal Node/Electron bootstrap script (~150-200 lines) that initializes HakuNeko's engine and exposes a WebSocket JSON-RPC server on `:9876`.
2. **Dynamic Docker Build:** The `Dockerfile.daemon` image clones upstream HakuNeko at build time from GitHub (`https://github.com/manga-download/hakuneko.git`), installs runtime dependencies, and mounts our `daemon/` bridge on top.
3. **Evergreen Updates:** Whenever upstream publishes fixes to broken scrapers or adds new connectors, the scraper image is simply rebuilt (`docker compose build --no-cache ...`) to immediately pull the latest engine code.

## Consequences
### Positive
- Zero upstream maintenance burden or merge conflict resolution.
- Our project repository stays clean, lightweight, and strictly focused on web features.
- Connectors remain evergreen.

### Negative / Trade-offs
- Docker build requires network access to GitHub during container image compilation.
- Version pinning via build arguments (e.g. `HAKUNEKO_VERSION=master` or specific commit hash) is recommended for build reproducibility.
