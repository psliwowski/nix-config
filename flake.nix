{
  description = "Standalone Home Manager Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cfg = {
      url = "path:./nix-config-template.nix";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      cfg,
      ...
    }:
    let
      lib = import ./lib.nix;
      cfgData = lib.mkCfg (import cfg);
      mkHost = lib.mkHost { inherit nixpkgs home-manager; };
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
      ];
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              just
              treefmt
              nixfmt
              stylua
              shfmt
              statix
              deadnix
              shellcheck
              prettier
              markdownlint-cli2
            ];
          };
        }
      );

      homeConfigurations = {
        "${cfgData.host.username}" = mkHost cfgData;
        default = mkHost cfgData;
      };

      checks = import ./checks.nix {
        mkHost = c: mkHost (lib.mkCfg c);
      };
    };
}
