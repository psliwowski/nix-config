# Nix Home Manager Configuration

A terminal environment and dotfiles for macOS and Linux, managed with Nix Flakes and Home Manager.

## Install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/psliwowski/nix-config/main/install.sh)"
```

Installs Nix if needed and sets up the core tools and shell configuration.

Open a new terminal after installation to use the configured shell and commands.

## Configure

Run `jg home edit` to edit `~/.nix-config`. Only core tools are enabled by default. Use `modules` to add optional modules and `configuration` for custom Home Manager settings:

```nix
modules = [ "text" "monitoring" "utilities" ];
configuration = {
  programs.bash.shellAliases.hello = "echo hello";
};
```

Apply your changes:

```bash
jg home switch
```

## Included tools

### Core (always enabled)

- **Bash** — interactive shell.
- **Git** (`gitMinimal`) — version control.
- **Starship** — shell prompt.
- **zoxide** (`z`) — jump to frequently used directories.
- **fzf** — fuzzy search for files and history.
- **ripgrep** (`rg`) — search file contents.
- **fd** — find files.
- **eza** — directory listings, used by the `ls`, `ll`, `la`, and `lt` aliases.
- **just** — run common commands.
- **Home Manager** — manage and activate your environment.

### `text` (optional)

- **Neovim** (`nvim`, `vim`, `vi`) — extensible modal text editor.
- **LazyVim** — Neovim configuration framework managed in `modules/nvim/` and linked to `~/.config/nvim`.
- **bat** — display files with syntax highlighting.
- **sd** — search and replace text.
- **choose** — select columns and fields.
- **jq** — query and transform JSON.
- **nil** — language server for Nix (`nil_ls`).
- **nixfmt** — formatter for Nix code.
- **lua-language-server** — language server for Lua (`lua_ls`).
- **stylua** — code formatter for Lua.
- **bash-language-server** — language server for Shell scripts (`bashls`).
- **shellcheck** — linter and static analysis for Shell scripts.
- **shfmt** — formatter for Shell scripts.
- Includes `tree-sitter` CLI for compiling Treesitter parsers (assumes host OS provides C compiler and `make`).

### `monitoring` (optional)

- **btop** — monitor CPU, memory, and processes.
- **procs** — list processes.
- **dust** — inspect directory sizes.
- **duf** — show disk usage and free space.

### `utilities` (optional)

- **xh** — make HTTP requests.
- **tealdeer** (`tldr`) — look up concise command examples.

### `container` (optional)

- **Podman** — run containers.
- **Docker Compose** — run multi-container applications with `podman compose`.

Add `"container"` to your `modules` list to enable it. On macOS, create a VM
once with `podman machine init`, then start it with `podman machine start`.
If you already have a Podman machine, start the existing machine instead.

Optionally set defaults for new machines in your configuration:

```nix
configuration.container.machine = {
  cpu = 4;
  memory = 10240; # MiB
  disk = 150; # GiB
};
```

Each setting is optional; omitted or `null` values keep Podman's defaults.
These settings generate `~/.config/containers/containers.conf.d/50-machine.conf`
and apply when running `podman machine init`. They do not change existing VMs.

The container module also installs `jg podman recreate`. It asks for confirmation,
stops and removes the default VM, then creates a replacement using the applied
machine defaults and leaves it stopped. This deletes the old VM's containers,
images, and volumes.

Each command below starts the existing default VM if needed. Run `up`, `down`,
and `pull` from the directory containing your Compose file; `ps`, `images`, and
`usage` work from any directory and report across projects:

| Command | Action |
| :--- | :--- |
| `jg podman start` | Start the default VM if stopped. |
| `jg podman stop` | Stop the default VM if no containers are running (`-f`/`--force` to force). |
| `jg podman recreate` | Delete and recreate the default VM using applied config. |
| `jg podman up` | Start services in the background (`compose up -d`). |
| `jg podman down` | Remove the project's containers and networks, then stop the VM if no containers remain running. |
| `jg podman pull` | Download service images, then stop the VM if no containers are running. |
| `jg podman ps` | List all containers, then stop the VM if no containers are running. |
| `jg podman images` | List images, then stop the VM if no containers are running. |
| `jg podman usage` | Show container, image, and volume disk usage, then stop the VM if no containers are running. |

Service names and Compose options are forwarded, for example `jg podman up db`
or `jg podman up --build`. `ps`, `images`, and `usage` forward other options to
Podman, for example `jg podman usage --verbose`.
Automatic shutdown happens only after a successful command and container check, and keeps the VM running if other containers are
active. These helpers assume your current Podman connection targets the default
machine. If the VM does not exist, create it first with `podman machine init`.

Run `jg home switch` to install the commands and apply any machine setting
changes before recreating the VM. Start the replacement with
`podman machine start` when needed. Use native `podman` commands for other actions.

### `vcs` (optional)

- **Jujutsu** (`jj`) — Git-compatible version control.
- **delta** — readable diffs.
- **GitHub CLI** (`gh`) — work with GitHub from the terminal.

Set the name and email used by both Git and Jujutsu in `~/.nix-config`:

```nix
configuration.vcs.user = {
  name = "Your Name";
  email = "you@example.com";
};
```

### `agents` (optional)

- **antigravity-cli** (`agy`) — terminal AI coding tool.
- **codex** — terminal AI coding tool.

## Commands

`jg` is an alias for `just -g`; run it to list global commands.

| Command | Action |
| :--- | :--- |
| `jg home edit` | Edit `~/.nix-config`. |
| `jg home switch` | Apply your configuration. |
| `hms` | Direct shortcut and fallback for `jg home switch`. |
| `jg home pull` | Pull committed configuration and package updates. Run `jg home switch` afterward to apply them. |
| `jg home repo` | Open a shell in the repository; use `exit` to return. |
| `jg home generations` | List past Home Manager generations. |
| `jg home gc` | Delete old Nix generations and collect garbage. |

For repository maintenance, run these inside the checkout:

| Command | Action |
| :--- | :--- |
| `just` | List repository commands. |
| `just check` | Evaluate macOS and Linux checks without building and validate all justfiles. |
| `just update-pkgs` | Update nixpkgs, commit, and push. |

## Uninstall

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/psliwowski/nix-config/main/uninstall.sh)"
```

Or run `./uninstall.sh` from the checkout. It removes Home Manager profiles, managed symlinks, local state, and `~/.nix-config`, and restores backed-up dotfiles. The checkout is also removed unless you run the uninstaller from inside it.

Nix remains installed by default. When running the local script, use `--remove-nix` to also invoke the Determinate Nix uninstaller, or `--yes` to skip confirmation.
