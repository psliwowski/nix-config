{ pkgs, ... }: {
  home.packages = with pkgs; [
    antigravity-cli
    codex
  ];
}
