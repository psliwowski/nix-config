set dotenv-load := false

repo_dir := env_var_or_default("NIX_CONFIG_REPO", env_var_or_default("XDG_CONFIG_HOME", env_var("HOME") / ".config") / "nix-config")
user_config := env_var("HOME") / ".nix-config"

# List available home recipes
default:
    @just --global-justfile --list home

# Open machine configuration (~/.nix-config) in your default editor
edit:
    ${VISUAL:-${EDITOR:-nano}} "{{user_config}}"

# Open a shell in the nix-config repository
repo:
    @echo "Opening shell in {{repo_dir}} (type 'exit' to return)..."
    @cd "{{repo_dir}}" && "$SHELL"
    @echo "Returned to original directory."

# Switch and activate Home Manager configuration
switch:
    home-manager switch -b backup --flake "{{repo_dir}}" --override-input cfg "path:{{user_config}}"

# Pull committed configuration and package updates
pull:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "==> Pulling latest repository changes..."
    nix run nixpkgs#gitMinimal -- -C "{{repo_dir}}" pull --ff-only

# Remove old Nix generations and run garbage collection
gc:
    nix-collect-garbage -d

# List past Home Manager generations
generations:
    home-manager generations
