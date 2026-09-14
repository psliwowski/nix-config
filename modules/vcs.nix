{ config, lib, pkgs, ... }:
let
  cfg = config.vcs.user;
  userSettings = lib.optionalAttrs (cfg.name != null || cfg.email != null) {
    user = (lib.optionalAttrs (cfg.name != null) { name = cfg.name; })
        // (lib.optionalAttrs (cfg.email != null) { email = cfg.email; });
  };
in {
  options.vcs.user = {
    name = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Default user name for VCS commits (Git and Jujutsu).";
    };
    email = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Default email for VCS commits (Git and Jujutsu).";
    };
  };

  config = {
    # 1. Jujutsu (jj)
    programs.jujutsu = {
      enable = true;
      settings = {
        ui = {
          paginate = "auto";
          pager = "delta";
        };
      } // userSettings;
    };

    # 2. Git
    programs.git = {
      enable = true;
      settings = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      } // userSettings;
    };

    # 3. Delta
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        line-numbers = true;
        side-by-side = false;
        navigate = true;
      };
    };

    # 4. GitHub CLI (gh)
    home.packages = [
      pkgs.gh
    ];
  };
}
