# ADR 0003: Embedded SQLite3 Persistence with WAL Mode

## Status
Accepted

## Context
In a Homelab deployment accessible across multiple personal devices, we need reliable, persistent storage for:

- User accounts and authentication tokens/sessions
- User bookmarks and followed series
- Per-user reading progress (current chapter, page index, completion timestamp)
- Persistent download queues and task histories

I previously considered connecting to an external PostgreSQL service on `proxy-net`. 

However, for a self-contained Homelab Manga reader, an external database introduces operational overhead (external network dependencies, DB credentials, migration orchestration race conditions) with no clear advantages.

Embedded databases like SQLite—which powers applications like Audiobookshelf, Kavita, Calibre-Web, Sonarr, and Radarr—are highly effective for Homelab media workloads because they eliminate network latency, require zero administration, and handle relational data efficiently. For few-users or small-household environments, they offer the perfect balance of performance and simplicity.

## Decision

We adopt **SQLite3** running in **WAL (Write-Ahead Logging)** mode via **SQLAlchemy 2.0** and **aiosqlite**:
- **Async Driver & ORM:** `SQLAlchemy 2.0` with `aiosqlite` for non-blocking asynchronous operations.
- **Connection Configuration:** 
  - On connection, execute `PRAGMA journal_mode=WAL;` and `PRAGMA foreign_keys=ON;` to enable concurrent reads and enforce relational integrity.
  - Set a busy timeout driver option (e.g., `timeout=30`) to gracefully queue concurrent write requests during sync or download spikes.
- **Storage Location:** Stored directly in the persistent data volume (`/app/data/nekoweb.db`).
- **Portability:** The data access layer uses standard SQLAlchemy models. If multi-instance horizontal clustering is ever desired, switching back to PostgreSQL requires only updating `DATABASE_URL`.

## Database Schema Model (Core Entities)
- `users`: User identity, password hashes, and profile settings.
- `bookmarks`: Followed series with connector IDs and metadata.
- `reading_progress`: Chapter index and page markers per user and title.
- `download_tasks`: Background download jobs, status, progress, and error logs.

## Consequences

### Positive
- **Zero-Dependency Deployment:** No external database containers or credentials required.
- **Microsecond Query Latency:** In-process disk I/O without TCP socket overhead.
- **Trivial Backup & Restore:** The entire database state is a single file (`nekoweb.db`). Safe, live hot-backups can be performed cleanly using SQLite's native online backup API or `VACUUM INTO` commands without stopping the application.
- **Database Agnostic:** Retains 100% SQLAlchemy portability.

### Negative / Trade-offs
- **Write Concurrency Limits:** Concurrency is limited to a single writer process at a time (mitigated by WAL mode, the busy timeout engine configuration, and an async worker queue).
- **Storage Environment Constraints:** Requires local disk/SSD storage. Running the SQLite file over network filesystems (NFS, SMB/CIFS) is strictly prohibited as it risks breaking file-locking mechanisms and causing silent database corruption.
