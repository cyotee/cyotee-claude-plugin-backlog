---
name: backlog
description: Manage tasks/ backlogs and worktrees created by the cyotee Claude plugin set.
metadata:
  short-description: Backlog/status/launch/complete/prune workflows for tasks/
---

# backlog (Codex)

Use this skill to mirror the Claude `/backlog` plugin flows inside Codex. It assumes the repository follows the `tasks/` structure described in the plugin README.

## Responsibilities
- Enumerate tasks by reading `tasks/INDEX.md` when present, otherwise infer from `tasks/[PREFIX]-[N]` directories.
- Display task details by reading `tasks/[ID]/PRD.md`, `PROGRESS.md`, and `REVIEW.md`.
- Launch work by creating/updating a worktree and generating `PROMPT.md` + `PROGRESS.md` guidance.
- Move tasks through `pending -> in_progress -> review -> complete` and archive when done.

## How to Use
- `status`: Summarize tasks by status with dependencies and worktrees. Prefer `tasks/INDEX.md`; if missing, scan `tasks/*` except `archive/`.
- `read <ID>`: Normalize IDs (allow `P-5` or `5` with detected prefix). Output PRD highlights (title, goals, acceptance criteria) and the latest progress/review notes.
- `launch <ID>`:
  1) Resolve repo root (`git rev-parse --show-toplevel`) and expected worktree branch (commonly `feature/<kebab>` from PRD).  
  2) Create or reuse worktree via `plugins/backlog/scripts/wt-create.sh <branch> [repo-root]`.  
  3) Generate/refresh `PROMPT.md` in the worktree root with: task summary, completion promise (`TASK_COMPLETE`), instructions to update `tasks/[ID]/PROGRESS.md`, and memory/compact guidance.  
  4) Ensure `tasks/[ID]/PROGRESS.md` exists with a Checkpoints section; append a new entry noting the launch.  
  5) Mark status `in_progress` in `tasks/INDEX.md` (or add frontmatter to PRD if no index).  
  6) Print launch steps for the user (`cd <worktree>`, run Claude/Codex, start agent loop).
- `complete <ID>`: From the worktree, check clean state, rebase onto main (unless explicitly skipped), merge/fast-forward main, update status to `review`, and point the user to PR/QA steps.
- `prune [<ID>|--all]`: Move completed/reviewed tasks to `tasks/archive/`, update `INDEX.md`, and list any stale worktrees to delete (use `plugins/backlog/scripts/wt-remove.sh <branch> [repo-root]`).
- `list --worktrees-only`: Cross-reference `git worktree list` with tasks to show active branches and statuses.

## Key Files
- `tasks/INDEX.md` — canonical task table (layer name, prefix, status, worktree, deps).
- `tasks/[ID]/PRD.md`, `PROGRESS.md`, `REVIEW.md` — task docs to read/write.
- `PROMPT.md` (in worktrees) — agent instructions; regenerate when launching if stale.
- Scripts: `plugins/backlog/scripts/wt-create.sh`, `wt-remove.sh`, `deps.sh` (dependency checks).

## Conventions
- Layer/prefix detection: read `tasks/INDEX.md` for `layer`/`prefix`; else derive prefix from repo/dir name first letter.
- Status icons: 🆕 `pending`, 🚀 `in_progress`, 📋 `review`, ✅ `complete`. Respect any existing icon mapping.
- Dependencies: mark tasks blocked if prerequisites are not `complete`/`review`.
- Be non-destructive with user files; append to `PROGRESS.md` instead of overwriting unless asked.
