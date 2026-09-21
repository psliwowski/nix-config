{ pkgs, ... }: {
  # 1. Neovim text editor & LazyVim configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Dependencies & language servers for LazyVim
    extraPackages = with pkgs; [
      tree-sitter

      # Lua language server & formatter
      lua-language-server
      stylua

      # JSON language server
      vscode-langservers-extracted

      # Nix language server, formatter & linter
      nil
      nixfmt
      statix

      # Shell (sh/bash) language server, linter & formatter
      bash-language-server
      shellcheck
      shfmt
    ];
  };

  # Link version-controlled LazyVim configuration into ~/.config/nvim
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };

  # 2. Modern text inspection, search, and stream processing
  programs.bat = {
    enable = true;
    config = {
      theme = "base16";
      pager = "less -FR";
      style = "header-filename,numbers,changes,rule,snip";
      map-syntax = [
        "*justfile:Makefile"
        "*.just:Makefile"
      ];
    };
  };

  programs.jq.enable = true;

  home.packages = with pkgs; [
    sd
    choose
    stylua
    nixfmt
    shfmt
    shellcheck
  ];
}
