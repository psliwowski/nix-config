{
  # WARNING: Do not change username or system; must match your active OS user and machine architecture.
  host = {
    username = "nix";
    system = "aarch64-darwin";
    # homeDirectory = "/Users/nix"; # optional
  };
  modules = [
    "text"
    "monitoring"
    "utilities"
    "container"
    "vcs"
    "agents"
  ];
  configuration = {
    # Optional defaults for new Podman machines:
    # container.machine = {
    #   cpu = 4;
    #   memory = 10240; # MiB
    #   disk = 150; # GiB
    # };
    vcs.user = {
      name = "Nix User";
      email = "user@nix.com";
    };
    # Machine-specific overrides or extensions, e.g.:
    # programs.git.package = null;
  };
}
