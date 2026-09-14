rec {
  # Home directory resolver using host config and pkgs platform detection
  mkHomeDir = { cfg, pkgs }:
    let
      username = cfg.host.username;
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
    in
      if (cfg.host.homeDirectory or null) != null
      then cfg.host.homeDirectory
      else if isDarwin then "/Users/${username}"
      else if username == "root" then "/root"
      else "/home/${username}";

  # Constructor enforcing the configuration manifest interface and resolving configuration decisions
  mkCfg = { host, modules ? [], configuration ? {} }@rawCfg:
    let
      isNonEmptyStr = v: builtins.isString v && v != "";
      modules = rawCfg.modules or [];
      configuration = rawCfg.configuration or {};
      homeDirectory = host.homeDirectory or null;
    in
      assert builtins.isAttrs host || abort "mkCfg: host must be an attribute set with username and system";
      assert isNonEmptyStr (host.username or null) || abort "mkCfg: host.username must be a non-empty string.";
      assert isNonEmptyStr (host.system or null) || abort "mkCfg: host.system must be a non-empty string (e.g. 'aarch64-darwin' or 'x86_64-linux')";
      assert homeDirectory == null || isNonEmptyStr homeDirectory || abort "mkCfg: host.homeDirectory must be a non-empty string if provided.";
      assert builtins.isList modules || abort "mkCfg: modules must be a list of module names";
      assert (builtins.isAttrs configuration || builtins.isFunction configuration)
        || abort "mkCfg: configuration must be an attribute set or function";
      {
        host = {
          username = host.username;
          system = host.system;
          homeDirectory = homeDirectory;
        };
        modules = modules;
        configuration = configuration;
      };

  # Host builder function taking nixpkgs, home-manager, modulesDir, returning a builder for cfg
  mkHost = { nixpkgs, home-manager, modulesDir ? ./modules }:
    cfg:
      let
        system = cfg.host.system;
        pkgs = import nixpkgs {
          system = system;
          config.allowUnfree = true;
        };
      in
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          extraSpecialArgs = {
            host = cfg.host;
          };
          modules = [
            {
              programs.home-manager.enable = true;
              home = {
                username = cfg.host.username;
                homeDirectory = mkHomeDir {
                  cfg = cfg;
                  pkgs = pkgs;
                };
                stateVersion = "26.11";
              };
            }
            cfg.configuration
          ] ++ (map (name: modulesDir + "/${name}.nix") cfg.modules);
        };
}
