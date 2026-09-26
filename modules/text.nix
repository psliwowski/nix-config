{ pkgs, ... }:
{
  # 1. Neovim text editor & LazyVim configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Treesitter syntax parsing is independent of LSPs, formatters, and linters.
    extraPackages = [ pkgs.tree-sitter ];
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
  ];
}
