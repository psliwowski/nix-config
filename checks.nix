{ mkHost }:
let
  testHost = {
    username = "runner";
  };
in {
  "aarch64-darwin" = {
    macos = (mkHost {
      host = testHost // {
        system = "aarch64-darwin";
      };
      modules = [
        "cli"
        "vcs"
        "agents"
        "ghostty"
      ];
    }).activationPackage;
  };
  "x86_64-linux" = {
    linux = (mkHost {
      host = testHost // {
        system = "x86_64-linux";
      };
      modules = [
        "cli"
        "vcs"
        "agents"
      ];
    }).activationPackage;
  };
}
