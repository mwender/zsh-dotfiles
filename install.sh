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
    echo "copy: ${src} -> ${dst}"
    return 0
  fi

  if [[ -e "$dst" ]]; then
    rm -rf -- "$dst"
  fi

  if command -v rsync >/dev/null 2>&1; then
    rsync -a -- "$src" "$dst"
  else
    # Fallback for systems without rsync.
    cp -R -p -- "$src" "$dst"
  fi
}

items=()
while IFS= read -r -d '' item; do
  base="$(basename -- "$item")"
  case "$base" in
    .|..|.git|install.sh)
      continue
      ;;
    *)
      items+=("$item")
      ;;
  esac
done < <(find "$REPO_DIR" -maxdepth 1 -mindepth 1 -print0)

if [[ ${#items[@]} -eq 0 ]]; then
  echo "No files found to install." >&2
  exit 1
fi

if $BACKUP; then
  for item in "${items[@]}"; do
    target="${HOME_DIR}/$(basename -- "$item")"
    if [[ -e "$target" ]]; then
      if $DRY_RUN; then
        echo "backup: ${target} -> ${backup_dir}/"
      else
        mkdir -p -- "$backup_dir"
        mv -- "$target" "$backup_dir/"
      fi
    fi
  done
fi

for item in "${items[@]}"; do
  base="$(basename -- "$item")"
  target="${HOME_DIR}/${base}"
  copy_item "$item" "$target"
done

if $BACKUP; then
  if $DRY_RUN; then
    echo "backup dir: ${backup_dir}"
  else
    echo "Backups stored in: ${backup_dir}"
  fi
fi

echo "Install complete."
