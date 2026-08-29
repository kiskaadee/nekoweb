# ADR 0001: Two-Tier Headless Engine with Virtual Framebuffer (Xvfb)

## Status
Accepted

## Context
HakuNeko's core strength lies in its extensive library of 1,200+ scrapers (connectors). However, these connectors are not simple HTTP scrapers; they heavily utilize browser DOM APIs, dynamic JavaScript execution, and hidden Electron `BrowserWindow` instances (`FetchWindowScript`, `FetchWindowPreloadScript`) to bypass Cloudflare Turnstile, DDoS protection, and client-side anti-scraping challenges.

Standard web browsers on client devices cannot execute these scrapers directly due to CORS restrictions, header spoofing limitations, and network isolation. Furthermore, a pure Node.js rewrite using Cheerio or simple HTTP clients would break Cloudflare-gated connectors.

## Decision
We adopt a **Two-Tier Architecture**:
1. Run the upstream HakuNeko Electron engine headlessly inside a containerized Linux environment backed by `xvfb-run` (virtual framebuffer).
2. Expose an internal JSON-RPC interface over WebSocket (`:9876`) within the private container network.
3. The dedicated backend API Gateway communicates with this headless daemon to execute scraping and downloading operations.

```
┌─────────────────────────────────┐
│ nekoweb-backend (FastAPI)       │
└──────────────┬──────────────────┘
               │ WebSocket RPC (:9876) [Internal network only]
               ▼
┌─────────────────────────────────┐
│ nekoweb-daemon (Daemon)         │
│  ├── xvfb-run (Virtual Display) │
│  ├── Chromium Renderer Context  │
│  └── 1,200+ Connectors Engine   │
└─────────────────────────────────┘
```

## Consequences
### Positive
- **100% Upstream Compatibility:** Connectors run inside the exact Chromium environment they were written for.
- **Cloudflare & Anti-Bot Bypass:** Native `BrowserWindow` challenge handling works out of the box.
- **Decoupled Lifecycle:** The heavy scraping engine can restart or scale independently from the web gateway.

### Negative / Trade-offs
- **Container Footprint:** The Electron container requires Chromium runtime dependencies and an Xvfb virtual display layer (~500MB–800MB RAM depending on concurrency).
- **RPC Translation Layer:** All scraper operations (search, fetch chapters, fetch pages, download) must be marshaled across the internal WebSocket RPC contract.
