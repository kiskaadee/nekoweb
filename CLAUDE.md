# Claude Code Specialized Directives

## Progressive Context Loading
- Do not load external rule files for simple localized code edits.
- Read `AGENTS.md` before making changes affecting database schema, package dependencies, Git state, or cross-component contracts.
- Read `docs/ARCHITECTURE.md` before modifying API routes, WebSocket events, or Daemon RPC methods.

## Build & Tool Execution Commands
- **Backend Lock:** `cd backend && uv lock` (Never use raw `pip`)
- **Backend Run:** `cd backend && uv run uvicorn app.main:app --reload`
- **Backend Migration:** `cd backend && uv run alembic upgrade head`
- **Test Suite:** `cd backend && uv run pytest`
- **Frontend Setup:** `cd frontend && pnpm install`
- **Frontend Dev:** `cd frontend && pnpm dev`

## Auto-Approve Verification Safeguards
- **Permitted Read Operations:** `git status`, `git diff`, `ls`, `cat`, file viewers
- **Restricted Write Operations:** Multi-file architectural refactors or dependency migrations require direct user confirmation (`/plan` first).
- **Destructive Commands Prohibited:** Never execute `git reset`, `git clean`, `git restore`, or `git checkout` on uncommitted files without explicit permission.
