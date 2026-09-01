#!/usr/bin/env bash
# Symlink dotfile packages into $HOME with GNU Stow.
#
#   ./install.sh              # stow every package
#   ./install.sh hypr waybar  # stow only the named packages
#   ./install.sh -n           # dry run, show what would happen
#   ./install.sh -D           # unstow (remove the symlinks)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_ACTION="-S"
STOW_FLAGS=()

while getopts ":nDh" opt; do
  case "$opt" in
    n) STOW_FLAGS+=("--no" "--verbose") ;;
    D) STOW_ACTION="-D" ;;
    h) awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"; exit 0 ;;
    \?) echo "unknown option: -$OPTARG" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

if ! command -v stow >/dev/null 2>&1; then
  echo "error: GNU Stow is not installed." >&2
  echo "  Gentoo:  sudo emerge app-admin/stow" >&2
  echo "  Debian:  sudo apt install stow" >&2
  echo "  Arch:    sudo pacman -S stow" >&2
  echo "  macOS:   brew install stow" >&2
  exit 1
fi

# Every directory that is not dot-prefixed is a package.
mapfile -t ALL_PACKAGES < <(
  find "$DOTFILES_DIR" -maxdepth 1 -mindepth 1 -type d \
       -not -name '.*' -not -name docs -printf '%f\n' | sort
)

if [ "$#" -gt 0 ]; then
  PACKAGES=("$@")
  for p in "${PACKAGES[@]}"; do
    [ -d "$DOTFILES_DIR/$p" ] || { echo "error: no such package: $p" >&2; exit 1; }
  done
else
  PACKAGES=("${ALL_PACKAGES[@]}")
fi

echo "==> ${#PACKAGES[@]} package(s): ${PACKAGES[*]}"
echo

FAILED=()
for p in "${PACKAGES[@]}"; do
  if stow "$STOW_ACTION" "${STOW_FLAGS[@]+"${STOW_FLAGS[@]}"}" \
          --dir "$DOTFILES_DIR" --target "$HOME" "$p"; then
    echo "  ok    $p"
  else
    echo "  FAIL  $p" >&2
    FAILED+=("$p")
  fi
done

if [ "${#FAILED[@]}" -gt 0 ]; then
  echo
  echo "==> ${#FAILED[@]} package(s) failed: ${FAILED[*]}" >&2
  echo "    A conflict usually means a real file already sits where the" >&2
  echo "    symlink should go. Move it aside and re-run." >&2
  exit 1
fi

# Configs whose real values are deliberately not in the repo.
echo
NEEDS_SECRETS=0
while IFS= read -r example; do
  target="${example%.example}"
  if [ ! -e "$target" ]; then
    [ "$NEEDS_SECRETS" -eq 0 ] && echo "==> Fill in your own values:"
    NEEDS_SECRETS=1
    printf '    cp %s \\\n       %s\n' "${example/#$HOME/\~}" "${target/#$HOME/\~}"
  fi
done < <(find "$DOTFILES_DIR" -name '*.example' -type f | sort)

echo
echo "==> Done."
