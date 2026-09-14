{ pkgs, ... }: {
  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      command = "${pkgs.bashInteractive}/bin/bash -l";
      shell-integration-features = "ssh-env,ssh-terminfo";
    };
  };
}
