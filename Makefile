# Images et modèles Dev Container.
#
#   make build [toolchain...]   construit devenv-<toolchain>:latest (tout sans argument ou avec "all")
#   make push [toolchain...]    envoie les images sur HOST (docker save | ssh docker load)
#   make check                  hadolint (Dockerfiles), shellcheck + shfmt (scripts), JSON valides
#
# Exemples : make build sys   make build   make push sys HOST=srv-m720q

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

HOST ?= srv-m720q

ALL_TOOLCHAINS := $(patsubst images/%/Dockerfile,%,$(wildcard images/*/Dockerfile))

# Arguments de build/push : les buts de la ligne de commande qui ne sont pas des
# commandes. Vide ou "all" = toutes les toolchains.
ARGS := $(filter-out build push check all lint-docker lint-shell lint-json,$(MAKECMDGOALS))
TOOLCHAINS := $(if $(or $(ARGS),$(filter all,$(MAKECMDGOALS))),$(if $(ARGS),$(ARGS),$(ALL_TOOLCHAINS)),$(ALL_TOOLCHAINS))

.PHONY: all build push check lint-docker lint-shell lint-json

all: build

build:
	scripts/build.sh $(TOOLCHAINS)

# Pas de registre : un seul hôte. docker load sur l'hôte utilise le contexte par
# défaut de l'utilisateur SSH (rootless).
push:
	@for t in $(TOOLCHAINS); do \
		echo "==> devenv-$$t:latest -> $(HOST)"; \
		docker save "devenv-$$t:latest" | ssh "$(HOST)" docker load; \
	done

check: lint-docker lint-shell lint-json

# hadolint local s'il existe, sinon son image officielle.
lint-docker:
	@for f in images/*/Dockerfile; do \
		echo "hadolint $$f"; \
		if command -v hadolint >/dev/null; then hadolint "$$f"; \
		else docker run --rm -i hadolint/hadolint < "$$f"; fi; \
	done

lint-shell:
	@command -v shellcheck >/dev/null || { echo "shellcheck introuvable" >&2; exit 1; }
	@command -v shfmt >/dev/null || { echo "shfmt introuvable" >&2; exit 1; }
	shellcheck scripts/*.sh
	shfmt -d -i 4 scripts/*.sh

lint-json:
	@command -v jq >/dev/null || { echo "jq introuvable" >&2; exit 1; }
	@for f in templates/*/devcontainer.json; do echo "jq $$f"; jq empty "$$f"; done

# Les noms de toolchain passés en argument ne sont pas des cibles.
.DEFAULT:
	@:
