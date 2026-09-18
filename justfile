set dotenv-load := false

# List available repository recipes
default:
    @just --list

# Evaluate checks for every supported system without building
check:
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
