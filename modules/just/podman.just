set dotenv-load := false
set no-cd

# List available Podman recipes
default:
    @just --global-justfile --list podman

# Delete and recreate the default machine using applied config; leave it stopped
[confirm("Delete the default Podman VM and all its containers, images, and volumes? The replacement will remain stopped.")]
recreate:
    podman machine rm --force
    podman machine init

# Start the default Podman machine if stopped
start:
    #!/usr/bin/env bash
    set -euo pipefail

    state=$(podman machine inspect --format '{{ '{{' }}.State}}')
    case "$state" in
        running) ;;
        stopped) podman machine start ;;
        *) echo "Cannot start: Podman machine state is $state" >&2; exit 1 ;;
    esac

# Stop the default Podman machine if no containers are running (-f/--force to stop unconditionally)
[arg("force", long, short="f", value="true")]
stop force="false":
    #!/usr/bin/env bash
    set -euo pipefail

    state=$(podman machine inspect --format '{{ '{{' }}.State}}')
    case "$state" in
        stopped) exit 0 ;;
        running) ;;
        *) echo "Cannot stop: Podman machine state is $state" >&2; exit 1 ;;
    esac

    if [[ "{{force}}" != "true" ]]; then
        # A failed query must not be treated as an empty container list.
        containers=$(podman ps --quiet)
        if [[ -n "$containers" ]]; then
            echo "Leaving the Podman machine running: containers are still active."
            exit 0
        fi
    fi

    podman machine stop

# Start the VM if needed and start Compose services in the background
up *args: start
    podman compose up -d {{args}}

# Remove Compose services and stop the VM if no containers are running
down *args: && stop
    podman compose down {{args}}

# Pull Compose images; stop the VM if no containers are running
pull *args: start && stop
    podman compose pull {{args}}

# List all containers; stop the VM if no containers are running
ps *args: start && stop
    podman ps --all {{args}}

# List images; stop the VM if no containers are running
images *args: start && stop
    podman images {{args}}

# Show container storage usage; stop the VM if no containers are running
usage *args: start && stop
    podman system df {{args}}
