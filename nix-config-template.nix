{
  # WARNING: Do not change username or system; must match your active OS user and machine architecture.
  host = {
    username = "nix";
    system = "aarch64-darwin";
    # homeDirectory = "/Users/nix"; # optional
  };
  modules = [
    "cli"
    "vcs"
    "agents"
    "ghostty"
  ];
  configuration = {
    vcs.user = {
      name = "Nix User";
      email = "user@nix.com";
    };
    # Machine-specific overrides or extensions, e.g.:
    # programs.git.package = null;
  };
}
