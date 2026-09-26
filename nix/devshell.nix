{
  nixpkgs,
  flake-utils,
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
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    devShells.default = pkgs.mkShellNoCC {
      name = "nix-config";

      packages = with pkgs; [
        just
        treefmt
        dprint
        nixfmt
        shfmt
        stylua
      ];
    };
  }
)
