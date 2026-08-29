# ADR 0002: Dedicated FastAPI + UV API Gateway

## Status
Accepted

## Context
The user interface and external API consumers require a high-performance, asynchronous REST and WebSocket gateway to manage application state, coordinate long-running downloads, stream and proxy chapter images to clients with caching headers, and serve the Single Page Application (SPA).

We need a modern backend ecosystem that offers fast startup times, strict type safety, asynchronous task scheduling, and deterministic package management.

## Decision
We choose **FastAPI** running on **Python 3.12+**, managed by **uv**:
- **Package Management:** `uv` provides lightning-fast dependency resolution, reproducible builds via `uv.lock`, and zero-overhead virtual environments.
- **Web Framework:** `FastAPI` + `Uvicorn` with standard WebSocket support.
- **RPC Client:** Async WebSocket client (`websockets`) connecting to the Headless Electron daemon with automatic reconnect and message request-response correlation.
- **Static Assets:** FastAPI mounts the pre-built React SPA static bundle on `/` while serving REST endpoints on `/api/*` and WebSocket event streams on `/ws/events`.

## Consequences
### Positive
- Single unified container for API, WebSocket hub, and Frontend static serving behind Traefik.
- High developer velocity and interactive OpenAPI documentation (`/docs`).
- Native async Python concurrency for non-blocking RPC calls and image streaming.

### Negative / Trade-offs
- Requires maintaining the Python-to-TypeScript RPC client mapping.
