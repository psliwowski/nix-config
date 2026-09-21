{
  config,
  lib,
  pkgs,
  ...
}:
{
  # 1. Base command runner for global tasks
  home.packages = [ pkgs.just ];

  # Ensure user-installed Nix tools take priority over system and Homebrew binaries
  home.sessionPath = [
    "$HOME/.nix-profile/bin"
  ];

  # 2. Shell Environment (GNU Bash)
  programs.bash = {
    enable = true;
    package = pkgs.bashInteractive;
    bashrcExtra = ''
      if [[ -o interactive ]] && [[ -x "$HOME/.nix-profile/bin/bash" ]] && [[ "$BASH" != "$HOME/.nix-profile/bin/bash" ]] && [[ "$BASH" != *"/nix/store/"* ]]; then
        export SHELL="$HOME/.nix-profile/bin/bash"
        exec "$HOME/.nix-profile/bin/bash" -l
      fi
    '';
    enableCompletion = true;
    historyControl = [
      "ignoredups"
      "ignorespace"
    ];
    historySize = 10000;
    historyFileSize = 50000;
    shellOptions = [
      "histappend"
      "checkwinsize"
      "globstar"
      "extglob"
    ];
    profileExtra = ''
      if [ -f ~/.env.local ]; then
        set -a
        . ~/.env.local
        set +a
      fi
      if [ -f ~/.bash_profile.local ]; then
        . ~/.bash_profile.local
      fi
    '';
    initExtra = ''
      if [ -f ~/.env.local ]; then
        set -a
        . ~/.env.local
        set +a
      fi
      if [ -f ~/.bashrc.local ]; then
        . ~/.bashrc.local
      fi
    '';
    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      lt = "eza --tree";
      j = "just";
      jg = "just -g";
      hms = "just -f ${lib.escapeShellArg "${config.xdg.configHome}/just/home.just"} switch";
    };
  };

  # 3. macOS defaults to /bin/zsh. Ensure interactive zsh sessions switch to Nix GNU Bash.
  home.file.".zshrc" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    text = ''
      if [[ -o interactive ]] && [[ -x "$HOME/.nix-profile/bin/bash" ]]; then
        export SHELL="$HOME/.nix-profile/bin/bash"
        exec "$HOME/.nix-profile/bin/bash" -l
      fi
    '';
  };

  # 4. Shell prompt & navigation
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;
    };
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
    defaultCommand = "fd --type f --strip-cwd-prefix --hidden --exclude .git";
    fileWidget.command = "fd --type f --strip-cwd-prefix --hidden --exclude .git";
    changeDirWidget.command = "fd --type d --strip-cwd-prefix --hidden --exclude .git";
  };

  # 5. Search primitives (files & text)
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case"
      "--hidden"
      "--glob=!.git/*"
    ];
  };

  programs.fd = {
    enable = true;
    hidden = true;
    ignores = [ ".git/" ];
  };

  # 6. Directory listing & navigation
  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    git = true;
    icons = "auto";
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };

  # 7. Global command runner (just)
  xdg.configFile."just/justfile".source = ./just/justfile;
  xdg.configFile."just/home.just".source = ./just/home.just;

  # 8. Version control primitive (git)
  programs.git = {
    enable = true;
    package = pkgs.gitMinimal;
    includes = [
      { path = "~/.config/git/config.local"; }
      { path = "~/.gitconfig.local"; }
    ];
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      fetch.prune = true;
      diff.algorithm = "histogram";
      merge.conflictStyle = "zdiff3";
      rebase.autoStash = true;
      branch.sort = "-committerdate";
      column.ui = "auto";
      commit.verbose = true;
      rerere.enabled = true;
      status = {
        short = true;
        branch = true;
      };
      alias = {
        unstage = "reset HEAD --";
        nuke = "reset --hard HEAD";
        slog = "log --oneline";
      };
    };
  };
}
