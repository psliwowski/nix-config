set dotenv-load := false

# List available repository recipes
default:
    @just --list

# Format Nix, Lua, shell, and Markdown files with pinned tools
fmt:
    nix develop --no-update-lock-file -c treefmt

# Verify formatting without modifying files
fmt-check:
    nix develop --no-update-lock-file -c treefmt --ci

# Lint Nix, shell, and Markdown files and validate justfiles
lint:
    nix develop --no-update-lock-file -c bash scripts/lint.sh

# Check formatting, linting, and evaluate every supported system without building
check: fmt-check lint
    nix flake check --all-systems --no-build --no-update-lock-file

# Pull, update only nixpkgs, commit the lockfile, and push
update-pkgs:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -n "$(git status --porcelain --untracked-files=all)" ]]; then
        echo "Commit or stash existing changes before running update-pkgs." >&2
        exit 1
    fi

    git pull
    nix flake update nixpkgs
    if git diff --quiet -- flake.lock; then
        echo "nixpkgs is already up to date."
        exit 0
    fi

    git commit --only -m "chore: update nixpkgs" -- flake.lock
    git push
