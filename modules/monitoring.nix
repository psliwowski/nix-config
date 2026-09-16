{ pkgs, ... }: {
  # Modern system, process, and disk resource monitoring
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "Default";
      theme_background = false;
      update_ms = 1000;
      proc_tree = true;
    };
  };

  home.packages = with pkgs; [
    procs
    dust
    duf
  ];
}
