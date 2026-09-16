{ pkgs, ... }: {
  # Modern text inspection, search, and stream processing
  programs.bat = {
    enable = true;
    config = {
      theme = "base16";
      pager = "less -FR";
    };
  };

  programs.bash.shellAliases = {
    cat = "bat -pp";
  };

  programs.jq.enable = true;

  home.packages = with pkgs; [
    sd
    choose
  ];
}
