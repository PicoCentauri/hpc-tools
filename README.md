# hpc-tools

General SLURM/HPC helper shared across all `~/projects/*` projects: discover
run directories, submit jobs, check status, and sync data to/from a cluster.

## Setup

Symlink (or copy) `hpc.py` and `hpc.mk` somewhere every project can reach
them, e.g.:

```sh
ln -s ~/repos/hpc-tools/hpc.py ~/projects/hpc.py
ln -s ~/repos/hpc-tools/hpc.mk ~/projects/hpc.mk
```

Each project then just needs a one-line `Makefile`:

```makefile
include $(HOME)/repos/hpc-tools/hpc.mk
```

### Claude Code skill (optional)

`skills/hpc/SKILL.md` is a Claude Code skill documenting all of this — how
to use each command, and (importantly) the safety rules around `submit`
costing real money. To make Claude Code discover it, symlink the skill
directory into place (must be a real filesystem entry at that path, not an
include):

```sh
ln -s ~/repos/hpc-tools/skills/hpc ~/.claude/skills/hpc
```

## First-time project setup

```sh
make configure CLUSTER=alex REMOTE=/home/atuin/b311bb/b311bb10/<project>
```

Saves the cluster + its remote project-root path to `hpc.local.mk` (created
next to the project's `Makefile`, one `REMOTE_<cluster>` line per configured
cluster). Later calls fall back to this automatically. Configure again for
additional clusters the same project uses.

## Commands

| Command | Effect |
|---|---|
| `make configure CLUSTER=... REMOTE=...` | Save cluster/remote defaults for this project |
| `make discover` | List run dirs (any dir containing a `#SBATCH` submit script) + last cluster used |
| `make submit DIR=... [CLUSTER=...]` | **Dry run**: print resolved remote path + `#SBATCH` directives, don't submit |
| `make submit DIR=... [CLUSTER=...] CONFIRM=1` | Actually submit via `sbatch` over SSH; records the job in `RUNS.md` |
| `make status` | Live `squeue`/`sacct` check for every non-terminal job in `RUNS.md`; updates its Status column |
| `make sync [CLUSTER=...]` | Pull every discovered run dir from its last-tracked cluster |
| `make fetch DIR=... [CLUSTER=...]` | Pull one run dir on demand |
| `make pull [CLUSTER=...] [EXCLUDE=pattern]` | Manual: pull the whole current directory from remote |
| `make push [CLUSTER=...] [EXCLUDE=pattern]` | Manual: push the whole current directory to remote |

## Safety

`submit` never runs `sbatch` unless called with `CONFIRM=1`. Jobs cost real
money/allocation — get explicit confirmation for the *specific* job before
ever passing it, one job at a time, never in a loop over `discover`'s output.

## RUNS.md

Lives in each project's root, created on first `submit`. Append-only ledger
(one row per submission: date, cluster, dir, job ID, job name) with a Status
column that `make status` updates in place.
