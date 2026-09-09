#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME:?HOME is not set}"

BACKUP=true
DRY_RUN=false

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--no-backup] [--dry-run]

Copies all dotfiles from this repo into $HOME.

Options:
  --no-backup   Overwrite existing files without backing them up
  --dry-run     Show what would happen without making changes

Example:
  ./install.sh --dry-run
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-backup)
      BACKUP=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

backup_dir=""
if $BACKUP; then
  ts="$(date +"%Y%m%d_%H%M%S")"
  backup_dir="${HOME_DIR}/.dotfiles-backup-${ts}"
fi

copy_item() {
  local src="$1"
  local dst="$2"

  if $DRY_RUN; then
    echo "📋 copy (dry-run): ${src} -> ${dst}"
    return 0
  fi

  if [[ -e "$dst" ]]; then
    echo "🧹 remove: ${dst}"
    rm -rf -- "$dst"
  fi

  if command -v rsync >/dev/null 2>&1; then
    echo "📋 copy: ${src} -> ${dst}"
    if [[ -d "$src" ]]; then
      rsync -a -- "$src"/ "$dst"/
    else
      rsync -a -- "$src" "$dst"
    fi
  else
    # Fallback for systems without rsync.
    echo "📋 copy: ${src} -> ${dst}"
    if [[ -d "$src" ]]; then
      mkdir -p -- "$dst"
      cp -R -p -- "$src"/ "$dst"/
    else
      cp -R -p -- "$src" "$dst"
    fi
  fi
}

EXCLUDES=(
  ".git"
  "AGENTS.md"
  "install.sh"
)

# Directories whose CONTENTS are symlinked into $HOME/<name>/, one file at a
# time, rather than the directory being copied or replaced wholesale.
#
# Two reasons. Editing a script in the repo takes effect immediately and a
# `git pull` updates the installed command with no second step. And $HOME/bin
# already holds things this repo does not manage (hey, sshconn, subl) -- those
# must survive untouched, which replacing the directory would not allow.
LINK_INTO=(
  "bin"
)

is_link_into() {
  local candidate="$1"
  local d
  for d in "${LINK_INTO[@]}"; do
    [[ "$candidate" == "$d" ]] && return 0
  done
  return 1
}

link_contents() {
  local src_dir="$1"
  local dst_dir="$2"

  if ! $DRY_RUN; then
    mkdir -p -- "$dst_dir"
  fi

  local src base dst
  for src in "$src_dir"/*; do
    [[ -e "$src" ]] || continue
    base="$(basename -- "$src")"
    dst="${dst_dir}/${base}"

    # Already pointing at the right place: nothing to do, and nothing to back up.
    if [[ -L "$dst" && "$(readlink -- "$dst")" == "$src" ]]; then
      echo "✅ already linked: ${dst}"
      continue
    fi

    if [[ -e "$dst" || -L "$dst" ]]; then
      if $DRY_RUN; then
        echo "🧳 backup (dry-run): ${dst} -> ${backup_dir:-<no backup>}/"
      elif $BACKUP; then
        mkdir -p -- "$backup_dir"
        echo "🧳 backup: ${dst} -> ${backup_dir}/"
        mv -- "$dst" "$backup_dir/"
      else
        rm -rf -- "$dst"
      fi
    fi

    if $DRY_RUN; then
      echo "🔗 symlink (dry-run): ${dst} -> ${src}"
    else
      echo "🔗 symlink: ${dst} -> ${src}"
      ln -s -- "$src" "$dst"
    fi
  done
}

items=()
while IFS= read -r -d '' item; do
  base="$(basename -- "$item")"
  if [[ "$base" == "." || "$base" == ".." ]]; then
    continue
  fi
  for exclude in "${EXCLUDES[@]}"; do
    if [[ "$base" == "$exclude" ]]; then
      echo "⏭  skip: ${base}"
      continue 2
    fi
  done
  items+=("$item")
done < <(find "$REPO_DIR" -maxdepth 1 -mindepth 1 -print0)

if [[ ${#items[@]} -eq 0 ]]; then
  echo "No files found to install." >&2
  exit 1
fi

if $BACKUP; then
  for item in "${items[@]}"; do
    base="$(basename -- "$item")"
    # Handled per-file by link_contents, which backs up only what it replaces.
    if is_link_into "$base"; then
      continue
    fi
    target="${HOME_DIR}/${base}"
    if [[ -e "$target" ]]; then
      if $DRY_RUN; then
        echo "🧳 backup (dry-run): ${target} -> ${backup_dir}/"
      else
        mkdir -p -- "$backup_dir"
        echo "🧳 backup: ${target} -> ${backup_dir}/"
        mv -- "$target" "$backup_dir/"
      fi
    fi
  done
fi

for item in "${items[@]}"; do
  base="$(basename -- "$item")"
  target="${HOME_DIR}/${base}"
  if is_link_into "$base"; then
    link_contents "$item" "$target"
  else
    copy_item "$item" "$target"
  fi
done

if $BACKUP; then
  if $DRY_RUN; then
    echo "🧳 backup dir (dry-run): ${backup_dir}"
  else
    echo "🧳 backups stored in: ${backup_dir}"
  fi
fi

echo "✅ install complete."
