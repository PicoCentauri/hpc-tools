# Shared SLURM/HPC helper targets — include from any project's Makefile,
# pointing at wherever this repo is cloned:
#
#   include $(HOME)/Repositories/hpc-tools/hpc.mk
#
# The project itself can live anywhere; its root is found by walking up from
# the cwd (see find_project_root in hpc.py).
#
# First time in a new project (or first time using a new cluster for it):
#   make configure CLUSTER=alex REMOTE=/home/hpc/b314bb/b314bb13/projects/<project>
# saves cluster + remote project-root path into hpc.local.mk (created next to
# this Makefile) so later calls don't need CLUSTER=... every time. The most
# recently configured cluster becomes the default.
#
# Targets:
#   make configure CLUSTER=... REMOTE=...
#   make discover
#   make submit DIR=... [CLUSTER=...]
#   make submit DIR=... [CLUSTER=...] CONFIRM=1     # real submission — confirm with the user first
#   make status
#   make sync [CLUSTER=...]
#   make fetch DIR=... [CLUSTER=...]
#   make pull [CLUSTER=...] [EXCLUDE=pattern]
#   make push [CLUSTER=...] [EXCLUDE=pattern]

HPC_TOOLS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
HPC := python3 $(HPC_TOOLS_DIR)hpc.py

.PHONY: configure discover submit status sync fetch pull push

configure:
	$(HPC) configure --cluster $(CLUSTER) --remote $(REMOTE)

discover:
	$(HPC) discover

submit:
	$(HPC) submit $(DIR) $(if $(CLUSTER),--cluster $(CLUSTER),) $(if $(CONFIRM),--confirm,)

status:
	$(HPC) status

sync:
	$(HPC) sync $(if $(CLUSTER),--cluster $(CLUSTER),)

fetch:
	$(HPC) fetch $(DIR) $(if $(CLUSTER),--cluster $(CLUSTER),)

pull:
	$(HPC) pull $(if $(CLUSTER),--cluster $(CLUSTER),) $(if $(EXCLUDE),--exclude $(EXCLUDE),)

push:
	$(HPC) push $(if $(CLUSTER),--cluster $(CLUSTER),) $(if $(EXCLUDE),--exclude $(EXCLUDE),)
