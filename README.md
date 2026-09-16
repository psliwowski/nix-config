# Nix Home Manager Configuration

Declarative developer environment and dotfiles managed with **Nix Flakes** and **Home Manager**.

---

## Prerequisites

Before using this configuration, ensure the following are installed on your machine:

1. **Nix** (with Flakes enabled):
   If you don't have Nix installed, the [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) is recommended:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```
2. **Version Control**:
   **Git** to clone and track changes.

---

## Quick Start (Automated Installer)

Bootstrap a fresh machine with a single command (installs Nix, clones this repository, generates base `~/.nix-config`, and activates Home Manager):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/psliwowski/nix-config/main/install.sh)"
```

The installer will:
1. **Check Nix**: Reuses Nix if already present; otherwise installs Nix via the [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer).
2. **Checkout Repository**: Checks if `~/.config/nix-config` already exists (updates if present). Uses lightweight temporary `nix#gitMinimal` (`nix run nixpkgs#gitMinimal`) to clone.
3. **Configure Machine**: Detects machine architecture and active user to generate your base `~/.nix-config` profile.
4. **Switch**: Activates your configuration with Home Manager using `--override-input cfg path:$HOME/.nix-config`.

---

## Manual Setup

### 1. Clone the Repository
```bash
git clone https://github.com/psliwowski/nix-config.git ~/.config/nix-config
cd ~/.config/nix-config
```
> **Tip:** If Git is not installed on your host, you can checkout using lightweight `nix#gitMinimal`:
> ```bash
> nix run nixpkgs#gitMinimal -- clone https://github.com/psliwowski/nix-config.git ~/.config/nix-config
> ```

### 2. Configure Your Machine
Create your local machine configuration file at `~/.nix-config` from the provided template:

```bash
cp nix-config-template.nix ~/.nix-config
```

Edit `~/.nix-config` to specify your username, target architecture, and VCS identity:

```nix
{
  host = {
    username = "<username>";
    system = "aarch64-darwin"; # or "x86_64-linux"
    # homeDirectory = "/Users/<username>"; # optional, automatically resolved if omitted
  };
  modules = [
    "text"
    "monitoring"
    "utilities"
    "vcs"
    "agents"
  ];
  configuration = {
    vcs.user = {
      name = "Your Name";
      email = "your.email@example.com";
    };
  };
}
```

### 3. Initialize the Machine
Run the initial activation command pointing to your local `~/.nix-config`. You do not need Home Manager pre-installed; Nix will run it ephemerally:

```bash
nix run --no-write-lock-file home-manager -- switch -b backup --flake . --override-input cfg path:$HOME/.nix-config
```

> **Note:** Machine profile and user identity are loaded from `~/.nix-config` via `--override-input cfg path:$HOME/.nix-config`. The repository defaults `cfg` to `nix-config-template.nix` so the flake remains fully hermetic and testable.

Once initialized, `home-manager` and all configured CLI tools will be directly available in your `$PATH`.

---

## Updating the Host

### After Making Configuration Changes
Whenever you edit your `~/.nix-config` or `.nix` module files in this repository:

1. **Ensure repository files are tracked:**
   Nix Flakes strictly ignores untracked files in the repository. If you added new modules or modified existing repository files, stage them:
   ```bash
   git status
   git add <new-file>
   ```
   > **Note for Jujutsu (`jj`) users:** Run `jj status` to verify new files are tracked so they are visible to Nix in the backing Git index. (Your machine configuration at `~/.nix-config` resides outside the repo and does not need to be tracked in git).

2. **Apply changes:**
   ```bash
   home-manager switch -b backup --flake . --override-input cfg path:$HOME/.nix-config
   ```

### After Updating Packages
To pull the latest software versions from `nixpkgs`:

```bash
nix flake update                                                                     # Updates lockfile pins
home-manager switch -b backup --flake . --override-input cfg path:$HOME/.nix-config  # Applies updated packages
```

---

## Helpful Commands

You can run common workflows using the global `just` alias (`jg` = `just -g`), or directly with `nix` and `home-manager`:

| Global Shortcut | Native Command | Action |
| :--- | :--- | :--- |
| `jg` | `just -g` | List all available global recipes and submodules |
| `jg home edit` | `${VISUAL:-${EDITOR:-nano}} ~/.nix-config` | Opens local machine configuration in your default editor |
| `jg home repo` | `cd <repo_dir> && $SHELL` | Opens a shell session inside the repository (type `exit` to return) |
| `jg home switch` | `home-manager switch -b backup --flake . --override-input cfg path:$HOME/.nix-config` | Applies configuration using your local `~/.nix-config` |
| `jg home check` | `nix flake check` | Runs automated sandbox builds and assertion tests for all supported architectures |
| `jg home update` | `git pull --ff-only` + `nix flake update` | Pulls latest repository commits (via `nix#gitMinimal`) and updates flake lockfile pins |
| `jg home upgrade` | `jg home update` + `jg home switch` | Pulls git changes, updates flake inputs, and applies configuration in one step |
| `jg home gc` | `nix-collect-garbage -d` | Removes old generations and frees disk space |
| `jg home generations` | `home-manager generations` | Lists past generations you can roll back to |

---

## Feature Modules

The configuration is organized into modular, self-contained cross-platform feature sets:

#### Core Architecture (`modules/core.nix`)
The foundational shell environment and command runner are automatically included for all hosts (mandatory base):
* **GNU Bash & Shell Trampolines**: Installs modern GNU Bash (`bashInteractive`) across macOS and Linux with generous history (`10,000` entries), deduplication, modern options (`globstar`, `extglob`), and local override hooks (`~/.env.local`, `~/.bashrc.local`, `~/.bash_profile.local`). Automatically trampolines host shells (macOS Zsh and host Linux Bash) into modern Nix GNU Bash (`~/.nix-profile/bin/bash -l`) upon interactive launch.
* **Shell Prompt & Navigation:**
  * **`starship`**: Fast, customizable cross-shell prompt.
  * **`zoxide`** (`z`): Smarter `cd` command with frecency-based directory jumping.
  * **`fzf`**: Interactive fuzzy finder for history (`Ctrl-R`), file selection (`Ctrl-T`), and directory navigation (`Alt-C`) in a compact popup.
  * **`eza`**: Feature-rich `ls` replacement with git status, icons, and tree views (aliased to `ls`, `ll`, `la`, `lt`).
* **Search Primitives:**
  * **`ripgrep`** (`rg`): Ultra-fast recursive line-oriented search tool respecting `.gitignore`.
  * **`fd`**: Fast, user-friendly alternative to `find`, powering `fzf` file and directory widgets.
* **Command Runner & Global Justfile:**
  * **`just`**: Command runner guaranteed on all hosts. Configured with a global justfile at `~/.config/just/justfile` and shortcut aliases `j` (`just`) and `jg` (`just -g`).
  * Submodules (`mod? <name>`) provide global namespaces (e.g. `jg home <recipe>`), and `mod? local` automatically discovers machine-specific custom recipes placed at `~/.config/just/local.just`.

### Optional Feature Modules
Configure in `~/.nix-config` under `modules = [ ... ]`:

#### 1. `modules/text.nix` (File Inspection & Data Processing)
* **`bat`**: Syntax-highlighting `cat` replacement with Git integration (aliased to `cat`).
* **`sd`**: Intuitive search and replace tool replacing `sed` with standard regex.
* **`choose`**: Human-friendly column and field selector replacing `cut` and basic `awk`.
* **`jq`**: Lightweight command-line JSON processor.

#### 2. `modules/monitoring.nix` (System & Resource Monitoring)
* **`btop`**: Resource monitor showing CPU, memory, disks, network, and processes in a modern TUI.
* **`procs`**: Modern, colored process viewer replacing `ps`.
* **`dust`**: Visual, tree-style disk usage analyzer replacing `du`.
* **`duf`**: Colorized disk usage overview replacing `df`.

#### 3. `modules/utilities.nix` (Productivity & Networking)
* **`xh`**: Fast, modern HTTP client for API testing and requests (Rust equivalent of `httpie`).
* **`tealdeer`** (`tldr`): Fast client providing concise, practical command cheat sheets.

#### 4. `modules/vcs.nix` (Version Control & Collaboration)
* **`git`** (`gitMinimal`): Lightweight, dependency-optimized build (~35 MB vs ~1.4 GB closure) with sane modern defaults (`main` default branch, `pull.rebase = true`, `push.autoSetupRemote = true`). Commit identity is configured declaratively via `vcs.user` in `~/.nix-config`. Automatically includes `~/.gitconfig.local` for machine-specific overrides (signing keys, work proxies, credential helpers).
* **`jujutsu`** (`jj`): Next-generation Git-compatible VCS with first-class conflict handling, working-copy snapshots, and pager integration with Delta. Commit identity configured via `vcs.user`. Supports local overrides via `~/.config/jj/conf.d/*.toml`.
* **`delta`**: Syntax-highlighting pager for git and jujutsu diffs.
* **`gh`**: Official GitHub CLI.

#### 5. `modules/agents.nix` (AI Coding Agents)
* **`antigravity-cli`** (`agy`): Google's Go-based terminal user interface agent client.
* **`codex`**: Lightweight coding agent that runs directly in your terminal.

---

## Uninstallation

To completely remove `nix-config`, safely unlink Home Manager dotfiles, restore your original `.backup` files, and clean up local state and caches:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/psliwowski/nix-config/main/uninstall.sh)"
```

Or run locally from the repository:

```bash
./uninstall.sh
```

Options:
* `-y, --yes, -f, --force`: Non-interactive mode (skips confirmation prompt).
* `--remove-nix`: Also invokes the Determinate Nix uninstaller (`/nix/nix-installer uninstall`).


