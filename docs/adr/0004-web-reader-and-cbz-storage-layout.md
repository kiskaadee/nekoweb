# ADR 0004: In-Browser Web Reader & Standard CBZ Storage Layout

## Status
Accepted

## Context
Traditional HakuNeko relied on local file system viewers or third-party image apps. For a frictionless web experience, users need to:
1. Read manga directly in their browser without downloading first (ad-hoc streaming).
2. Download entire chapters to a shared server directory that can be read offline or cataloged by media servers like Kavita, Komga, or Jellyfin.

Earlier exploration considered integrating host-level `mpv` player control over UNIX domain sockets for living-room TV playback. However, this introduced host-level process coupling and complexity outside the core mission of an ad-hoc web manga platform.

## Decision
1. **Frontend Web Reader:** Build a high-performance, responsive React web reader supporting:
   - **Continuous Vertical Scroll (Webtoon Mode):** Smooth vertical reading with dynamic image preloading.
   - **Paged Reader Mode:** Single-page and side-by-side double-page layouts with Left-to-Right (LTR) and Right-to-Left (RTL) reading directions.
   - **Image Proxy & Caching:** FastAPI proxies external image URLs through `/api/reader/proxy` with HTTP caching headers to bypass client-side CORS and referrer restrictions.
2. **Download Archive Format & Metadata:**
   - Completed chapter downloads are packaged as `.cbz` (ZIP containing sorted page images).
   - Each `.cbz` includes a standard `ComicInfo.xml` file containing title, series, chapter number, author/artist, and summary metadata for immediate discovery by Kavita / Komga / Jellyfin.
3. **Scope Simplification:** Exclude host-level `mpv` player IPC to maintain a clean, containerized boundary.

## Storage Folder Convention
```
/srv/manga-storage/
└── {Manga Title}/
    └── {Manga Title} - c{Chapter Number} [{Chapter Title}].cbz
        └── (ComicInfo.xml embedded inside each .cbz archive)
```

> **Note:** `ComicInfo.xml` is packaged **inside** each `.cbz` file alongside the sorted page images, not as a standalone file on the filesystem. This is the standard expected by Kavita, Komga, and Jellyfin for per-chapter metadata discovery.

## Consequences
### Positive
- Rich, distraction-free reading experience on mobile, tablet, and desktop.
- 100% compatibility with the wider homelab comic/manga server ecosystem.
- Clean container isolation with no host-side process dependencies.

### Negative / Trade-offs
- The server must handle temporary image buffering and zip compression during chapter downloads.
