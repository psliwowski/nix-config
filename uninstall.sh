#!/usr/bin/env bash
#
# uninstall.sh - Uninstalls nix-config, restores dotfiles, and removes Home Manager
#
# Can be run via:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/psliwowski/nix-config/main/uninstall.sh)"
#

# Guarantee Bash execution even if invoked with `sh`
if [ -z "${BASH_VERSION:-}" ]; then
  exec /bin/bash "$0" "$@"
fi

set -euo pipefail

setup_colors() {
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    COLOR_RESET=$'\033[0m'
    COLOR_BOLD=$'\033[1m'
    COLOR_DIM=$'\033[2m'
    COLOR_BLUE=$'\033[34m'
    COLOR_GREEN=$'\033[32m'
    COLOR_YELLOW=$'\033[33m'
    COLOR_RED=$'\033[31m'
    COLOR_CYAN=$'\033[36m'
  else
    COLOR_RESET=""
    COLOR_BOLD=""
    COLOR_DIM=""
    COLOR_BLUE=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_RED=""
    COLOR_CYAN=""
  fi
}

info() {
  printf "%s==>%s %s\n" "${COLOR_BLUE}${COLOR_BOLD}" "${COLOR_RESET}" "$*"
}

success() {
  printf "%s==>%s %s%s%s\n" "${COLOR_GREEN}${COLOR_BOLD}" "${COLOR_RESET}" "${COLOR_GREEN}" "$*" "${COLOR_RESET}"
}

warn() {
  printf "%sWARNING:%s %s\n" "${COLOR_YELLOW}${COLOR_BOLD}" "${COLOR_RESET}" "$*" >&2
}

error() {
  printf "%sERROR:%s %s\n" "${COLOR_RED}${COLOR_BOLD}" "${COLOR_RESET}" "$*" >&2
}

title() {
  echo ""
  printf "%s=== %s ===%s\n" "${COLOR_CYAN}${COLOR_BOLD}" "$*" "${COLOR_RESET}"
}

confirm_uninstall() {
  if [ "${NON_INTERACTIVE:-0}" = "1" ]; then
    return 0
  fi

  local prompt_label="Are you sure you want to uninstall nix-config and remove Home Manager?"
  printf "%s %s[y/N]%s " "$prompt_label" "${COLOR_DIM}" "${COLOR_RESET}" >&2
  local reply=""
  if [ -t 0 ]; then
    read -r reply || true
  elif [ -r /dev/tty ]; then
    read -r reply </dev/tty || true
  else
    reply="n"
  fi

  case "$reply" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *)
      info "Uninstallation cancelled."
      exit 0
      ;;
  esac
}

print_usage() {
  cat <<EOF
Usage: uninstall.sh [OPTIONS]

Uninstalls nix-config, removes Home Manager profiles and symlinks,
restores backed up dotfiles, and cleans up local caches.

Options:
  -y, --yes, -f, --force  Uninstall without confirmation
      --remove-nix        Also run the Determinate Nix uninstaller (/nix/nix-installer uninstall)
  -h, --help              Show this help message
EOF
}

clean_dotfiles() {
  title "Step 1: Removing Symlinks and Restoring Dotfiles"

  local profiles_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"
  local candidate_paths=()

  # 1. Collect all paths across all historical Home Manager generations
  local gen_dir
  for gen_dir in "$profiles_dir"/home-manager*-link "$profiles_dir"/home-manager; do
    if [ -d "$gen_dir/home-files" ]; then
      while IFS= read -r rel_path; do
        [ -n "$rel_path" ] || continue
        candidate_paths+=("$rel_path")
      done < <(cd "$gen_dir/home-files" && find . -type l 2>/dev/null | sed 's|^\./||')
    fi
  done

  # 2. Add known module paths as safety net (in case older generations were garbage collected)
  local known_paths=(
    ".bashrc"
    ".bash_profile"
    ".profile"
    ".gitconfig"
    ".config/git/config"
    ".config/jj/config.toml"
    ".config/starship.toml"
    ".config/ghostty/config"
  )
  candidate_paths+=("${known_paths[@]}")

  # 3. Deduplicate candidate paths (POSIX / Bash 3.2 compatible)
  local unique_paths=()
  local path_line
  while IFS= read -r path_line; do
    [ -n "$path_line" ] || continue
    unique_paths+=("$path_line")
  done < <(printf "%s\n" "${candidate_paths[@]}" | sort -u)

  # 4. Inspect each path: unlink Home Manager symlinks and restore .backup files
  local rel_path
  for rel_path in "${unique_paths[@]}"; do
    local target="$HOME/$rel_path"
    local backup="${target}.backup"

    # Case A: Target is a Home Manager symlink
    if [ -L "$target" ]; then
      local dest
      dest="$(readlink "$target" 2>/dev/null || true)"
      if [[ "$dest" == *"/nix/store/"* ]] || [[ "$dest" == *"home-manager"* ]]; then
        rm -f "$target"
        UNLINKED_FILES+=("$rel_path")

        if [ -e "$backup" ]; then
          mv "$backup" "$target"
          RESTORED_FILES+=("$rel_path")
        else
          rmdir -p "$(dirname "$target")" 2>/dev/null || true
        fi
      fi
    # Case B: Target doesn't exist, but .backup exists (orphaned backup from removed module)
    elif [ ! -e "$target" ] && [ -e "$backup" ]; then
      mv "$backup" "$target"
      RESTORED_FILES+=("$rel_path")
    # Case C: Target exists as regular file, and .backup also exists
    elif [ -e "$target" ] && [ -e "$backup" ]; then
      warn "Found ${backup}, but $target exists as a regular file. Preserved backup."
    fi
  done

  if [ ${#UNLINKED_FILES[@]} -gt 0 ]; then
    success "Removed ${#UNLINKED_FILES[@]} Home Manager symlinks from $HOME."
  else
    info "No active Home Manager symlinks found to remove."
  fi

  if [ ${#RESTORED_FILES[@]} -gt 0 ]; then
    info "Restored ${#RESTORED_FILES[@]} original files from .backup extension:"
    local f
    for f in "${RESTORED_FILES[@]}"; do
      echo "  - ~/${f}"
    done
  fi
}

clean_home_manager_state() {
  title "Step 2: Cleaning Home Manager State and Profiles"

  local hm_state="${XDG_STATE_HOME:-$HOME/.local/state}/home-manager"
  local hm_cache="${XDG_CACHE_HOME:-$HOME/.cache}/home-manager"
  local hm_data="${XDG_DATA_HOME:-$HOME/.local/share}/home-manager"
  local hm_profile_prefix="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/home-manager"

  rm -f "${hm_profile_prefix}"*
  rm -rf "$hm_state"
  rm -rf "$hm_cache"
  rm -rf "$hm_data"

  success "Removed Home Manager profiles, state, cache, and data directories."

  if command -v nix-collect-garbage >/dev/null 2>&1; then
    info "Running nix-collect-garbage to prune unreferenced store paths..."
    nix-collect-garbage 2>/dev/null || true
    success "Garbage collection complete."
  fi
}

clean_user_config() {
  title "Step 3: Cleaning Configuration File"

  if [ ! -e "$USER_CONFIG" ]; then
    info "No configuration file found at $USER_CONFIG."
    return 0
  fi

  mv "$USER_CONFIG" "${USER_CONFIG}.bak"
  success "Archived configuration file to ${USER_CONFIG}.bak."
}

clean_repo() {
  title "Step 4: Cleaning Repository Directory"

  if [ ! -d "$CONFIG_DIR" ]; then
    info "Repository directory $CONFIG_DIR does not exist."
    return 0
  fi

  local real_pwd real_config
  real_pwd="$(cd "$PWD" && pwd -P 2>/dev/null || echo "$PWD")"
  real_config="$(cd "$CONFIG_DIR" && pwd -P 2>/dev/null || echo "$CONFIG_DIR")"

  if [[ "$real_pwd" == "$real_config"* ]]; then
    warn "Currently running inside $CONFIG_DIR; skipping deletion."
    info "You can remove the repository directory after exiting:"
    echo "  rm -rf $CONFIG_DIR"
  else
    rm -rf "$CONFIG_DIR"
    success "Removed repository directory at $CONFIG_DIR."
  fi
}

handle_nix_uninstallation() {
  if [ "$REMOVE_NIX" != "1" ]; then
    return 0
  fi

  title "Step 5: Uninstalling Nix"

  if [ -x "/nix/nix-installer" ]; then
    info "Invoking Determinate Nix uninstaller (/nix/nix-installer uninstall)..."
    /nix/nix-installer uninstall
    success "Nix uninstalled successfully."
  else
    warn "Determinate Nix uninstaller not found at /nix/nix-installer."
    warn "Please consult https://github.com/DeterminateSystems/nix-installer to remove Nix manually."
  fi
}

print_completion_message() {
  echo ""
  echo "============================================================"
  echo " 🎉 Uninstallation Complete!"
  echo "============================================================"
  echo "nix-config and Home Manager have been successfully removed."

  if [ "$REMOVE_NIX" != "1" ] && [ -x "/nix/nix-installer" ]; then
    echo ""
    echo "Nix remains installed on your machine. To also remove Nix, run:"
    echo "  /nix/nix-installer uninstall"
  fi

  echo ""
  echo "To restart your shell in your clean environment:"
  echo "  exec bash -l"
  echo "============================================================"
}

main() {
  setup_colors

  CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nix-config"
  USER_CONFIG="${HOME}/.nix-config"
  NON_INTERACTIVE=0
  REMOVE_NIX=0

  UNLINKED_FILES=()
  RESTORED_FILES=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -y|--yes|-f|--force|--non-interactive)
        NON_INTERACTIVE=1
        shift
        ;;
      --remove-nix)
        REMOVE_NIX=1
        shift
        ;;
      -h|--help)
        print_usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        print_usage
        exit 1
        ;;
    esac
  done

  echo "============================================================"
  echo " nix-config Uninstaller"
  echo "============================================================"

  confirm_uninstall

  clean_dotfiles
  clean_home_manager_state
  clean_user_config
  clean_repo
  handle_nix_uninstallation

  print_completion_message
}

main "$@"
