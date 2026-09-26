{
  description = "Standalone Home Manager Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    cfg = {
      url = "path:./nix/nix-config-template.nix";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      flake-utils,
      cfg,
      ...
    }:
    let
      lib = import ./nix/lib.nix;
      cfgData = lib.mkCfg (import cfg);
      mkHost = lib.mkHost { inherit nixpkgs home-manager; };
    in
    {
      homeConfigurations = {
        "${cfgData.host.username}" = mkHost cfgData;
      };

      checks =
        (import ./nix/checks.nix {
          inherit flake-utils;
          mkHost = c: mkHost (lib.mkCfg c);
        }).checks;

      devShells =
        (import ./nix/devshell.nix {
          inherit nixpkgs flake-utils;
        }).devShells;
    };
}
