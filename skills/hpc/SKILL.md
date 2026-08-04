---
name: hpc
description: Work with SLURM HPC clusters from any project — discover runs, submit jobs, check status, sync/fetch/pull/push data. Backed by the shared ~/Repositories/hpc-tools/{hpc.py,hpc.mk}. Use when the user asks to fetch/pull/push/sync simulation data, submit or resubmit a job, check job/queue status, or find which run directories exist.
user-invocable: true
allowed-tools:
  - Read
  - Bash(python3 ~/Repositories/hpc-tools/hpc.py *)
  - Bash(make discover)
  - Bash(make status)
  - Bash(make configure*)
  - Bash(make sync*)
  - Bash(make fetch*)
  - Bash(make pull*)
  - Bash(make push*)
  - Bash(make submit*)
  - Bash(ssh * squeue*)
  - Bash(ssh * sacct*)
---

# HPC / SLURM tooling

Arguments passed: `$ARGUMENTS`

Shared, general tooling — not project-specific — for working with SLURM
clusters from any project, wherever it lives on disk. Source lives in the git
repo `~/Repositories/hpc-tools` (`hpc.py` for the logic, `hpc.mk` for Make
targets). A project opts in with a one-line `Makefile`:

```makefile
include $(HOME)/Repositories/hpc-tools/hpc.mk
```

No cluster name or remote path is hardcoded anywhere in the shared tooling —
every project configures its own. The project root is located by walking up
from the cwd to the nearest `hpc.local.mk`, else a `Makefile` that includes
`hpc.mk`, else a git repository root.

## First-time setup for a project (or a new cluster for an existing one)

```
make configure CLUSTER=alex REMOTE=/home/hpc/b314bb/b314bb13/projects/<project>
```

Saves to `hpc.local.mk` next to the project's `Makefile` (auto-generated,
one `REMOTE_<cluster>` line per configured cluster, plus `DEFAULT_CLUSTER`
pointing at whichever was configured most recently). Every other command
falls back to this when `CLUSTER=` is omitted. A subdirectory's remote path
is always `REMOTE_<cluster>` + that path's position relative to the project
root (mirrors local structure).

If a command errors with "No cluster configured" / "No remote path
configured", that's this step missing — ask the user for the cluster name
and the absolute remote path for the project root, then run `configure`.

## Commands

- **`make discover`** — list every "run dir" in the project: a directory
  containing a submit script (`srun.sh`, `submit.sh`, `run.sh`, or `job.sh`
  with an `#SBATCH` directive inside). Shows the last cluster each was
  submitted to, from `RUNS.md`.
- **`make status`** — for every job in `RUNS.md` not yet in a terminal state
  (COMPLETED/FAILED/CANCELLED/TIMEOUT/...), live-checks `squeue`/`sacct` on
  its cluster and updates the Status column in place. Read-only otherwise.
- **`make sync [CLUSTER=x]`** — pull every discovered run dir from its
  last-tracked cluster (per `RUNS.md`). Dirs never submitted, or whose
  tracked cluster was never `configure`d, are skipped with a note.
- **`make fetch DIR=... [CLUSTER=...]`** — pull just one run dir, any time,
  regardless of tracking state. `CLUSTER` falls back to the project default.
- **`make pull [CLUSTER=...] [EXCLUDE=pattern]`** — manual, whole-project raw
  sync: mirrors the current directory from the remote. Safe, additive (no
  `--delete`), fine to run whenever the user asks for "the current state" of
  the cluster side without needing per-run tracking.
- **`make push [CLUSTER=...] [EXCLUDE=pattern]`** — same, reversed direction
  (local → remote). This can overwrite remote files.
- **`make submit DIR=... [CLUSTER=...]`** — **dry run only**: prints the
  resolved remote path and the submit script's `#SBATCH` directives
  (job name, partition, time, nodes, gpus, ...). Does **not** submit.
- **`make submit DIR=... [CLUSTER=...] CONFIRM=1`** — actually runs `sbatch`
  over SSH and, on success, appends a row to `RUNS.md` (date, cluster, dir,
  job ID, job name, status=SUBMITTED).

## Safety — jobs cost real money. Read this before ever passing CONFIRM=1.

- **Always run the dry-run form first** (no `CONFIRM`) and show the user the
  exact output: cluster, remote path, script, and the parsed `#SBATCH`
  directives (partition, time, node/GPU count — the things that determine
  cost/allocation burn).
- **Get explicit, fresh confirmation in the current conversation** for that
  specific job before adding `CONFIRM=1`. A prior approval for a different
  job, or an approval earlier in a long conversation for "the general idea,"
  does not count — confirm the specific submission, every time.
- **Never submit more than one job per confirmation.** If the user wants
  several run dirs submitted, either get one confirmation that explicitly
  lists all of them with their individual configs, or confirm one at a time
  — never loop `make submit ... CONFIRM=1` across a discovered list without
  the user having seen each specific job first.
- **Never make `discover` or any other read-only command imply consent to
  submit.** Listing run dirs is not the same as being told to launch them.
- `push`, `configure`, and `submit` itself are the commands here that touch
  remote state / cost money — `discover`, `status`, `sync`, `fetch`, `pull`
  are all safe to run without asking each time once the user's engaged with
  this workflow.

## Which cluster?

If a project has never been configured and it isn't already clear from
context which cluster/remote path to use, ask — don't guess. The wrong
cluster for `pull`/`fetch`/`sync` fails cleanly or syncs from an unrelated
existing path; for `submit` it's a real job launched on the wrong
allocation.

## RUNS.md

Lives at the project root, created on first `submit`. Append-only ledger
(new row per submission) with a Status column `status` updates in place.
Don't hand-edit it if avoidable — let `submit`/`status` maintain it, since
their row-matching is by exact Job ID string in column 4.
