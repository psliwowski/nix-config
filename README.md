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
- **Starship** — shell prompt.
- **zoxide** (`z`) — jump to frequently used directories.
- **fzf** — fuzzy search for files and history.
- **ripgrep** (`rg`) — search file contents.
- **fd** — find files.
- **eza** — directory listings, used by the `ls`, `ll`, `la`, and `lt` aliases.
- **just** — run common commands.
- **Home Manager** — manage and activate your environment.

### `text` (optional)

- **bat** — display files with syntax highlighting.
- **sd** — search and replace text.
- **choose** — select columns and fields.
- **jq** — query and transform JSON.

### `monitoring` (optional)

- **btop** — monitor CPU, memory, and processes.
- **procs** — list processes.
- **dust** — inspect directory sizes.
- **duf** — show disk usage and free space.

### `utilities` (optional)

- **xh** — make HTTP requests.
- **tealdeer** (`tldr`) — look up concise command examples.

### `vcs` (optional)

- **Git** (`gitMinimal`) — version control.
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
| `jg home pull` | Pull committed configuration and package updates. Run `jg home switch` afterward to apply them. |
| `jg home repo` | Open a shell in the repository; use `exit` to return. |
| `jg home generations` | List past Home Manager generations. |
| `jg home gc` | Delete old Nix generations and collect garbage. |

For repository maintenance, run these inside the checkout:

| Command | Action |
| :--- | :--- |
| `just` | List repository commands. |
| `just check` | Evaluate macOS and Linux checks without building. |
| `just update-pkgs` | Update nixpkgs, commit, and push. |

## Uninstall

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/psliwowski/nix-config/main/uninstall.sh)"
```

Or run `./uninstall.sh` from the checkout. It removes Home Manager profiles, managed symlinks, local state, and `~/.nix-config`, and restores backed-up dotfiles. The checkout is also removed unless you run the uninstaller from inside it.

Nix remains installed by default. When running the local script, use `--remove-nix` to also invoke the Determinate Nix uninstaller, or `--yes` to skip confirmation.
