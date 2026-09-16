set dotenv-load := false

repo_dir := if path_exists("flake.nix") == "true" { "." } else { env_var_or_default("XDG_CONFIG_HOME", env_var("HOME") / ".config") / "nix-config" }
user_config := env_var("HOME") / ".nix-config"

# List available home recipes
default:
    @just --global-justfile --list home

# Open machine configuration (~/.nix-config) in your default editor
edit:
    ${VISUAL:-${EDITOR:-nano}} {{user_config}}

# Open a shell in the nix-config repository
repo:
    @echo "Opening shell in {{repo_dir}} (type 'exit' to return)..."
    @cd "{{repo_dir}}" && "$SHELL"
    @echo "Returned to original directory."

# Switch and activate Home Manager configuration
switch:
    home-manager switch -b backup --flake {{repo_dir}} --override-input cfg path:{{user_config}}

# Run checks and assertions across all configurations
check:
    nix flake check {{repo_dir}}

# Pull git changes and update flake lockfile inputs
update:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "==> Pulling latest repository changes..."
    nix run nixpkgs#gitMinimal -- -C "{{repo_dir}}" pull --ff-only

    echo "==> Updating flake lockfile inputs..."
    nix flake update --flake "{{repo_dir}}"

# Pull git changes, update flake inputs, and activate configuration
upgrade: update switch

# Remove old Nix generations and run garbage collection
gc:
    nix-collect-garbage -d

# List past Home Manager generations
generations:
    home-manager generations
