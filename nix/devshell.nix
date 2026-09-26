{
  nixpkgs,
  flake-utils,
  devshell,
}:
let
  supportedSystems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];
in
flake-utils.lib.eachSystem supportedSystems (
  system:
  let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ devshell.overlays.default ];
    };
  in
  {
    devShells.default = pkgs.devshell.mkShell {
      name = "nix-config";

      packages = with pkgs; [
        just
      ];
    };
  }
)
