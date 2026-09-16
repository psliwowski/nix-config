{ pkgs, ... }: {
  # Modern productivity and API testing utilities
  programs.tealdeer = {
    enable = true;
    settings = {
      updates.auto_update = true;
    };
  };

  home.packages = with pkgs; [
    xh
  ];
}
