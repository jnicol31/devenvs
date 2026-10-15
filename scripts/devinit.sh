#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: %s [-f] <project> <toolchain> [<git-url>]\n' "${0##*/}" >&2
    printf '  -f   remplace .devcontainer/devcontainer.json s'"'"'il existe déjà\n' >&2
    exit 2
}

force=0
while getopts ':f' option; do
    case "$option" in
    f) force=1 ;;
    *) usage ;;
    esac
done
shift $((OPTIND - 1))

(($# == 2 || $# == 3)) || usage
project="$1"
toolchain="$2"
git_url="${3:-}"

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
project_dir="${DEV_ROOT}/projects/${project}"
destination="${project_dir}/.devcontainer/devcontainer.json"

if [[ ! -f "$template" ]]; then
    printf 'Unknown toolchain or missing template: %s\n' "$toolchain" >&2
    exit 1
fi

if [[ -e "$destination" && "$force" -eq 0 ]]; then
    printf 'Dev Container configuration already exists: %s (use -f to replace it)\n' "$destination" >&2
    exit 1
fi

# Dépôt Git : initialisé sur place (le dossier contient déjà .devcontainer, ce qui
# empêche "git clone"). La clé vient de l'agent SSH relayé : pas de clé sur le serveur.
if [[ -n "$git_url" ]]; then
    if [[ -d "${project_dir}/.git" ]]; then
        printf 'Git repository already present: %s\n' "$project_dir"
    else
        mkdir -p -- "$project_dir"
        git -C "$project_dir" init -q
        git -C "$project_dir" remote add origin "$git_url"
        git -C "$project_dir" fetch -q origin
        branch="$(git -C "$project_dir" ls-remote --symref origin HEAD | sed -n 's|^ref: refs/heads/\([^[:space:]]*\)[[:space:]]*HEAD$|\1|p')"
        if [[ -z "$branch" ]]; then
            printf 'Cannot find the default branch of %s\n' "$git_url" >&2
            exit 1
        fi
        git -C "$project_dir" checkout -q -b "$branch" --track "origin/${branch}"
        printf 'Cloned %s (%s) into %s\n' "$git_url" "$branch" "$project_dir"
    fi
    # Configuration locale au poste : hors du dépôt.
    mkdir -p -- "${project_dir}/.git/info"
    grep -qxF '.devcontainer/' "${project_dir}/.git/info/exclude" 2>/dev/null ||
        printf '.devcontainer/\n' >>"${project_dir}/.git/info/exclude"
fi

mkdir -p -- "$(dirname "$destination")"
cp -- "$template" "$destination"
printf 'Created %s\n' "$destination"
