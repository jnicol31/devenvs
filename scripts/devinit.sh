#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: %s <project> <toolchain>\n' "${0##*/}" >&2
    exit 2
}

(($# == 2)) || usage
project="$1"
toolchain="$2"

if [[ ! "$project" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ || "$project" == "." || "$project" == ".." ]]; then
    printf 'Invalid project name: %s\n' "$project" >&2
    exit 2
fi
if [[ ! "$toolchain" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
    printf 'Invalid toolchain name: %s\n' "$toolchain" >&2
    exit 2
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEV_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
template="${SCRIPT_DIR}/../templates/${toolchain}/devcontainer.json"
destination="${DEV_ROOT}/projects/${project}/.devcontainer/devcontainer.json"

if [[ ! -f "$template" ]]; then
    printf 'Unknown toolchain or missing template: %s\n' "$toolchain" >&2
    exit 1
fi

if [[ -e "$destination" ]]; then
    printf 'Dev Container configuration already exists: %s\n' "$destination" >&2
    exit 1
fi

mkdir -p -- "$(dirname "$destination")"
cp -- "$template" "$destination"
printf 'Created %s\n' "$destination"
