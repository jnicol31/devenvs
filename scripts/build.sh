#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

if (($# == 0)); then
    set -- sys
fi

for toolchain in "$@"; do
    if [[ ! "$toolchain" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
        printf 'Invalid toolchain name: %s\n' "$toolchain" >&2
        exit 1
    fi

    image_dir="${REPO_ROOT}/images/${toolchain}"
    if [[ ! -f "${image_dir}/Dockerfile" ]]; then
        printf 'Unknown toolchain or missing Dockerfile: %s\n' "$toolchain" >&2
        exit 1
    fi

    docker build --no-cache --tag "devenv-${toolchain}:latest" "$image_dir"
done
