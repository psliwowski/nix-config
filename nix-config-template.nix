{
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
