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
    "cli"
    "vcs"
    "agents"
    "ghostty"
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

Common daily workflows run directly with `home-manager` and `nix`:

| Command | Action |
| :--- | :--- |
| `home-manager switch -b backup --flake . --override-input cfg path:$HOME/.nix-config` | Applies configuration using your local `~/.nix-config` |
| `nix run --no-write-lock-file home-manager -- switch -b backup --flake . --override-input cfg path:$HOME/.nix-config` | Bootstraps Home Manager on a fresh machine |
| `nix flake check` | Runs automated sandbox builds and assertion tests for all supported architectures |
| `nix build .#homeConfigurations.default.activationPackage --override-input cfg path:$HOME/.nix-config` | Builds the activation package without applying |
| `nix flake update` | Updates flake inputs (e.g. `nixpkgs`, `home-manager`) |
| `nix-collect-garbage -d` | Removes old generations and frees disk space |
| `home-manager generations` | Lists past generations you can roll back to |

---

## Feature Modules

The configuration is organized into modular, self-contained cross-platform feature sets:

### 1. `modules/cli.nix` (Modern Terminal Toolbox & Shell)
* **Shell Environment:**
  * **GNU Bash**: Configures GNU Bash with generous history (`10,000` entries), deduplication, modern options (`globstar`, `extglob`), and local override hooks (`~/.bashrc.local`, `~/.bash_profile.local`). Automatically installs GNU Bash 5 on macOS while leveraging the host Linux shell.
* **Shell Prompt & Navigation:**
  * **`starship`**: Fast, customizable cross-shell prompt.
  * **`zoxide`** (`z`): Smarter `cd` command with frecency-based directory jumping.
  * **`fzf`**: Interactive fuzzy finder for history (`Ctrl-R`), file selection (`Ctrl-T`), and directory navigation (`Alt-C`) in a compact popup.
* **Search & File Management:**
  * **`ripgrep`** (`rg`): Ultra-fast recursive line-oriented search tool respecting `.gitignore`.
  * **`fd`**: Fast, user-friendly alternative to `find`.
  * **`bat`**: Syntax-highlighting `cat` replacement with Git integration (aliased to `cat`).
  * **`eza`**: Feature-rich `ls` replacement with git status, icons, and tree views (aliased to `ls`, `ll`, `la`, `lt`).
* **Text & Data Processing:**
  * **`sd`**: Intuitive search and replace tool replacing `sed` with standard regex.
  * **`choose`**: Human-friendly column and field selector replacing `cut` and basic `awk`.
  * **`jq`**: Lightweight command-line JSON processor.
* **System & Resource Monitoring:**
  * **`btop`**: Resource monitor showing CPU, memory, disks, network, and processes in a modern TUI.
  * **`procs`**: Modern, colored process viewer replacing `ps`.
  * **`dust`**: Visual, tree-style disk usage analyzer replacing `du`.
  * **`duf`**: Colorized disk usage overview replacing `df`.
* **Productivity & Utilities:**
  * **`xh`**: Fast, modern HTTP client for API testing and requests (Rust equivalent of `httpie`).
  * **`tealdeer`** (`tldr`): Fast client providing concise, practical command cheat sheets.
  * **`just`**: Command runner for project and repository tasks.

### 2. `modules/vcs.nix` (Version Control & Collaboration)
* **`git`**: Sane modern defaults (`main` default branch, `pull.rebase = true`, `push.autoSetupRemote = true`). Commit identity is configured declaratively via `vcs.user` in `~/.nix-config`.
* **`jujutsu`** (`jj`): Next-generation Git-compatible VCS with first-class conflict handling, working-copy snapshots, and pager integration with Delta. Commit identity configured via `vcs.user`.
* **`delta`**: Syntax-highlighting pager for git and jujutsu diffs.
* **`gh`**: Official GitHub CLI.

### 3. `modules/agents.nix` (AI Coding Agents)
* **`antigravity-cli`** (`agy`): Google's Go-based terminal user interface agent client.
* **`codex`**: Lightweight coding agent that runs directly in your terminal.

### 4. `modules/ghostty.nix` (Terminal Emulator)
* **`ghostty`**: Declaratively manages Ghostty terminal configuration (`~/.config/ghostty/config`), automatically setting `command = "${pkgs.bashInteractive}/bin/bash -l"` and shell integration features.
  > **Note:** macOS defaults to `/bin/zsh`. For terminal emulators not managed by this configuration (Terminal.app, iTerm2, Alacritty), configure them to launch with `~/.nix-profile/bin/bash -l`.

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


