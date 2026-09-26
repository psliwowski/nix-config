{
  flake-utils,
  mkHost,
}:
let
  supportedSystems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];
in
flake-utils.lib.eachSystem supportedSystems (system: {
  checks.activation =
    (mkHost {
      host = {
        username = "runner";
        inherit system;
      };
      modules = [
        "text"
        "monitoring"
        "utilities"
        "container"
        "vcs"
        "agents"
      ];
    }).activationPackage;
})
