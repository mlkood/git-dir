#!/usr/bin/env bash
set -euo pipefail

show_help() {
    cat <<'EOF'
Usage:
  git-dir [--dry-run] "<includes !excludes>" <repo-url>

Options:
  --dry-run     Show what would be done (no clone, no changes)
  --help        Show this help and exit

Pathspec rules:
  include        directory to include in the working tree
  !exclude       subdirectory to exclude

Examples:
  git-dir "docs resources/logo !resources/logo/print" https://github.com/USER/REPO.git
  git-dir --dry-run "docs !docs/assets" https://github.com/USER/REPO.git

Example directory name:
  example-repo_docs_(no assets)_resources-logo_(no print)
EOF
}

DRYRUN=0

if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

if [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

if [[ "$1" == "--dry-run" ]]; then
    DRYRUN=1
    SPEC="${2:-}"
    REPO="${3:-}"
else
    SPEC="${1:-}"
    REPO="${2:-}"
fi

if [[ -z "$SPEC" || -z "$REPO" ]]; then
    show_help
    exit 1
fi

# Split paths, drop empty
read -ra TOKENS <<<"$SPEC"

INCLUDES=()
EXCLUDES=()

for P in "${TOKENS[@]}"; do
    [[ -z "$P" ]] && continue
    if [[ "$P" == !* ]]; then
        EXCLUDES+=("${P:1}")
    else
        INCLUDES+=("$P")
    fi
done

# Deduplicate
mapfile -t INCLUDES < <(printf "%s\n" "${INCLUDES[@]}" | sort -u)
mapfile -t EXCLUDES < <(printf "%s\n" "${EXCLUDES[@]}" | sort -u)

REPONAME="$(basename "$REPO" .git)"

NAMEPARTS=()

for I in "${INCLUDES[@]}"; do
    I_SAFE="${I//\//-}"
    E_NAMES=()

    for E in "${EXCLUDES[@]}"; do
        [[ "$E" == "$I/"* ]] && E_NAMES+=("$(basename "$E")")
    done

    if [[ ${#E_NAMES[@]} -gt 0 ]]; then
        mapfile -t E_NAMES < <(printf "%s\n" "${E_NAMES[@]}" | sort -u)
        NAMEPARTS+=("${I_SAFE}_(no ${E_NAMES[*]})")
    else
        NAMEPARTS+=("$I_SAFE")
    fi
done

NAMEJOIN="$(IFS=_; echo "${NAMEPARTS[*]}")"
WORKDIR="$PWD/${REPONAME}_${NAMEJOIN}"

if [[ $DRYRUN -eq 1 ]]; then
    echo "[DRY-RUN]"
    echo "Repo:        $REPONAME"
    echo "Workdir:     $WORKDIR"
    echo "Includes:    ${INCLUDES[*]}"
    echo "Excludes:    ${EXCLUDES[*]}"
    echo "Sparse-set:  $SPEC"
    echo "Clone:       SKIP"
    echo "Checkout:    SKIP"
    exit 0
fi

if [[ ! -d "$WORKDIR/.git" ]]; then
    mkdir -p "$WORKDIR"
    git clone --filter=blob:none --no-checkout "$REPO" "$WORKDIR"
fi

cd "$WORKDIR"

git sparse-checkout init --no-cone
git sparse-checkout set "${TOKENS[@]}"
git checkout

for I in "${INCLUDES[@]}"; do
    if [[ "$I" == */* ]]; then
        LINKNAME="$(basename "$I")"
        [[ ! -e "$LINKNAME" ]] && ln -s "$I" "$LINKNAME"
    fi
done
