{ pkgs, ... }: {
  # Modern text inspection, search, and stream processing
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
