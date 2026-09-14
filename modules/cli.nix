{ pkgs, ... }: {
  # 1. Shell Environment (GNU Bash)
  programs.bash = {
    enable = true;
    # macOS ships ancient Bash 3.2, so install modern GNU Bash 5 via Nix.
    # Linux already has modern Bash 5+, so use host system bash (package = null).
    package = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.bashInteractive else null;
    enableCompletion = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    historySize = 10000;
    historyFileSize = 50000;
    shellOptions = [
      "histappend"
      "checkwinsize"
      "globstar"
      "extglob"
    ];
    profileExtra = ''
      if [ -f ~/.bash_profile.local ]; then
        . ~/.bash_profile.local
      fi
    '';
    initExtra = ''
      if [ -f ~/.bashrc.local ]; then
        . ~/.bashrc.local
      fi
    '';
    shellAliases = {
      cat = "bat -pp";
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      lt = "eza --tree";
    };
  };

  # 2. Shell prompt & navigation
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

  # 3. Modern CLI replacements
  programs.bat = {
    enable = true;
    config = {
      theme = "base16";
      pager = "less -FR";
    };
  };

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

  programs.jq.enable = true;

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "Default";
      theme_background = false;
      update_ms = 1000;
      proc_tree = true;
    };
  };

  programs.tealdeer = {
    enable = true;
    settings = {
      updates.auto_update = true;
    };
  };

  # 4. Modern UNIX utilities & command runner
  home.packages = with pkgs; [
    just
    procs
    dust
    duf
    sd
    xh
    choose
  ];
}
