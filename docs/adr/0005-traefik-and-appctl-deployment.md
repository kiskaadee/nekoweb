# ADR 0005: Traefik v3 & appctl Homelab Integration

## Status
Accepted

## Context
Deployments in the target homelab environment follow standardized conventions defined in `/home/kiskaadee/Deployments/traefik-deployments`:
- External edge routing via **Traefik v3** attached to the shared `proxy-net` Docker network.
- Automated secret and configuration injection using **sops-nix** and the local **`appctl`** CLI wrapper.
- Automatic wildcard TLS certificate resolution via Let's Encrypt / Dynu DNS challenge.
- Optional ForwardAuth via Authelia.

## Decision
1. Package the deployment using standard Docker Compose (`deploy/docker-compose.yml`).
2. Only the `nekoweb-backend` container attaches to `proxy-net` and exposes Traefik routing labels.
3. The `nekoweb-daemon` container resides strictly on an internal bridge network (`nekoweb-internal`), accessible only by the backend.
4. Integrate lifecycle management with `appctl` by mapping standard environment variables (`SERVICE_DOMAIN`, `PROXY_NETWORK`, `CERT_RESOLVER`, `JWT_SECRET_KEY`, etc.).

## Container Topology & Network Diagram
```
                     [ Internet / LAN ]
                             │
                             ▼ (443 / TLS)
                     ┌───────────────┐
                     │  Traefik v3   │
                     └───────┬───────┘
                             │ (proxy-net)
                             ▼ (:8000)
             ┌────────────────────────┐
             │    nekoweb-backend     │
             │ (FastAPI + React SPA)  │
             └───────────┬────────────┘
                         │
                         │ (nekoweb-internal)
                         ▼ (:9876 WS RPC)
             ┌────────────────────────┐
             │     nekoweb-daemon     │
             │ (Headless Xvfb Engine) │
             └────────────────────────┘
```

## Consequences
### Positive
- Fully consistent with other homelab services (Jellyfin, Gitea, Excalidraw).
- Zero port conflicts on the host.
- Single command management via `appctl up nekoweb` / `appctl down nekoweb`.
