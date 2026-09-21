#!/usr/bin/env bash
#
# install.sh - Automated installer and bootstrapper for nix-config
#
# Can be run via:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/psliwowski/nix-config/main/install.sh)"
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
    COLOR_BLUE=$'\033[34m'
    COLOR_GREEN=$'\033[32m'
    COLOR_YELLOW=$'\033[33m'
    COLOR_RED=$'\033[31m'
    COLOR_CYAN=$'\033[36m'
  else
    COLOR_RESET=""
    COLOR_BOLD=""
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

install_nix() {
  title "Step 1: Checking Nix Installation"

  local nix_ver
  if nix_ver="$(nix --version 2>/dev/null)"; then
    warn "Nix is already installed: ${nix_ver}. Reusing existing installation."
    return 0
  fi

  info "Nix is not installed on this system."
  info "Installing Nix via Determinate Systems Installer (https://install.determinate.systems/nix)..."

  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

  # Source the nix daemon profile if nix is not yet in PATH in the current session
  if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    # shellcheck disable=SC1091
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  fi

  if ! nix_ver="$(nix --version 2>/dev/null)"; then
    error "Nix was installed, but the 'nix' executable was not found in PATH."
    error "Please restart your shell and re-run this script."
    exit 1
  fi

  success "Nix installed successfully: ${nix_ver}"
}

clone_repo() {
  title "Step 2: Checking nix-config Repository"

  local git_cmd=("nix" "run" "nixpkgs#gitMinimal" "--")

  if [ -d "$CONFIG_DIR" ]; then
    local current_origin
    if ! current_origin="$("${git_cmd[@]}" -C "$CONFIG_DIR" config --get remote.origin.url 2>/dev/null)"; then
      error "Directory $CONFIG_DIR exists but is not a Git repository."
      error "Please remove or backup $CONFIG_DIR before re-running this script."
      exit 1
    fi

    if [[ "$current_origin" != *"psliwowski/nix-config"* ]]; then
      error "Existing repository at $CONFIG_DIR points to an unexpected remote:"
      error "  Current:  ${current_origin}"
      error "  Expected: psliwowski/nix-config"
      error "Please remove or backup $CONFIG_DIR before re-running this script."
      exit 1
    fi

    if [ ! -f "$CONFIG_DIR/flake.nix" ]; then
      error "Directory $CONFIG_DIR is a psliwowski/nix-config repository, but flake.nix is missing."
      error "Please check or re-clone $CONFIG_DIR."
      exit 1
    fi

    warn "Found existing repository at $CONFIG_DIR. Fetching latest changes instead of fresh clone."
    "${git_cmd[@]}" -C "$CONFIG_DIR" fetch origin
    success "Repository at $CONFIG_DIR is up to date."
    return 0
  fi

  info "Cloning repository to $CONFIG_DIR using temporary nix#gitMinimal..."
  mkdir -p "$(dirname "$CONFIG_DIR")"
  "${git_cmd[@]}" clone "$REPO_URL" "$CONFIG_DIR"

  success "Successfully checked out repository to $CONFIG_DIR"
}

detect_system() {
  local sys
  if ! sys="$(nix eval --impure --raw --expr 'builtins.currentSystem' 2>/dev/null)" || [ -z "$sys" ]; then
    error "Failed to detect host system architecture using Nix."
    exit 1
  fi
  echo "$sys"
}

configure_machine() {
  title "Step 3: Machine Configuration ($USER_CONFIG)"

  if [ -f "$USER_CONFIG" ]; then
    warn "Configuration file $USER_CONFIG already exists. Skipping creation to preserve existing settings."
    return 0
  fi

  info "Auto-detecting host environment for $USER_CONFIG..."

  local host_user host_system
  host_user="$(id -un 2>/dev/null || echo "${USER:-}")"
  host_system="$(detect_system)"

  info "Detected user:   ${host_user}"
  info "Detected system: ${host_system}"

  cat >"$USER_CONFIG" <<EOF
{
  # WARNING: Do not change username or system; must match your active OS user and machine architecture.
  host = {
    username = "${host_user}";
    system = "${host_system}";
  };
  modules = [];
}
EOF

  success "Generated base configuration file at $USER_CONFIG"
  echo "------------------------------------------------------------"
  cat "$USER_CONFIG"
  echo "------------------------------------------------------------"
  echo ""
}

start_detect_backups() {
  if [ "$SKIP_DETECT_BACKUPS" = "1" ]; then
    return 0
  fi
  mktemp "${TMPDIR:-/tmp}/nix-config-marker.XXXXXX" 2>/dev/null || true
}

end_detect_backups() {
  local marker="$1"
  if [ "$SKIP_DETECT_BACKUPS" = "1" ] || [ -z "$marker" ] || [ ! -e "$marker" ]; then
    [ -n "$marker" ] && rm -f "$marker"
    return 0
  fi

  local hm_files="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/home-manager/home-files"

  if [ ! -d "$hm_files" ]; then
    warn "Could not locate Home Manager profile at $hm_files to inspect backups."
    rm -f "$marker"
    return 0
  fi

  local backed_up=()
  local rel_path
  while IFS= read -r rel_path; do
    [ -n "$rel_path" ] || continue
    local target="$HOME/$rel_path"
    local backup="${target}.backup"
    if [ -e "$backup" ]; then
      if [ -n "$(find "$backup" -cnewer "$marker" 2>/dev/null)" ]; then
        backed_up+=("$rel_path")
      fi
    fi
  done < <(cd "$hm_files" && find . -type l 2>/dev/null | sed 's|^\./||')

  rm -f "$marker"

  if [ ${#backed_up[@]} -gt 0 ]; then
    echo ""
    warn "The following existing files were displaced and backed up with .backup extension:"
    local f
    for f in "${backed_up[@]}"; do
      echo "  - ~/${f} -> ~/${f}.backup"
    done
  fi
}

run_switch() {
  title "Step 4: Initializing Home Manager"

  if [ "$SKIP_SWITCH" = "1" ]; then
    warn "Skipping switch activation (--no-switch specified)."
    print_manual_switch_instructions
    return 0
  fi

  info "The configuration will now be built and activated using:"
  echo "  cd $CONFIG_DIR"
  echo "  nix run --no-write-lock-file home-manager -- switch -b backup --flake . --override-input cfg path:$USER_CONFIG"
  echo ""

  local marker
  marker="$(start_detect_backups)"

  info "Running home-manager switch (this may take a few minutes on initial run)..."
  (
    cd "$CONFIG_DIR"
    nix run --no-write-lock-file home-manager -- switch -b backup --flake . --override-input cfg "path:$USER_CONFIG"
  )

  success "Home Manager configuration successfully applied!"
  end_detect_backups "$marker"

  print_completion_message
}

print_usage() {
  cat <<EOF
Usage: install.sh [OPTIONS]

Installs Nix, checks out the nix-config repository, sets up ~/.nix-config,
and activates Home Manager.

Options:
      --no-switch          Skip running home-manager switch after configuration
      --no-detect-backups  Skip detecting and reporting backed up files
  -h, --help               Show this help message
EOF
}

print_manual_switch_instructions() {
  echo ""
  echo "============================================================"
  echo " Installation Ready"
  echo "============================================================"
  echo "You can apply your configuration at any time by running:"
  echo "  cd $CONFIG_DIR"
  echo "  nix run --no-write-lock-file home-manager -- switch -b backup --flake . --override-input cfg path:$USER_CONFIG"
  echo "============================================================"
}

print_completion_message() {
  echo ""
  echo "============================================================"
  echo " 🎉 Installation Complete!"
  echo "============================================================"
  echo "Your base configuration and CLI environment have been activated."
  echo ""
  echo "To start using your new environment:"
  echo "  exec bash -l"
  echo ""
  echo "Useful commands:"
  echo "  - Apply future changes after editing $USER_CONFIG or modules:"
  echo "      home-manager switch -b backup --flake $CONFIG_DIR --override-input cfg path:$USER_CONFIG"
  echo "  - Update flake packages:"
  echo "      nix flake update --flake $CONFIG_DIR"
  echo "============================================================"
}

main() {
  setup_colors

  REPO_URL="https://github.com/psliwowski/nix-config.git"
  CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nix-config"
  USER_CONFIG="${HOME}/.nix-config"
  SKIP_SWITCH=0
  SKIP_DETECT_BACKUPS=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --no-switch)
        SKIP_SWITCH=1
        shift
        ;;
      --no-detect-backups)
        SKIP_DETECT_BACKUPS=1
        shift
        ;;
      -h | --help)
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
  echo " nix-config Installer"
  echo "============================================================"

  install_nix
  clone_repo
  configure_machine
  run_switch
}

main "$@"
