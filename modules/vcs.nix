{ config, lib, pkgs, ... }:
let
  cfg = config.vcs.user;
  userSettings = {
    user = (lib.optionalAttrs (cfg.name != null) { name = cfg.name; })
        // (lib.optionalAttrs (cfg.email != null) { email = cfg.email; });
  };
  colors = let
    esc = builtins.fromJSON "\"\\u001b\"";
  in {
    pink = "${esc}[38;5;212m";
    blue = "${esc}[38;5;75m";
    reset = "${esc}[0m";
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
        aliases.blame = [ "file" "annotate" ];
      } // userSettings;
    };

    # 2. Git (user settings & delta pager)
    programs.git = {
      settings = userSettings;
      iniContent.pager.blame = lib.mkForce "${lib.getExe pkgs.delta}";
    };

    # 3. Delta
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        features = "base16-lite";

        # Universal preferences
        navigate = true;
        line-numbers = true;
        side-by-side = false;
        hyperlinks = true;

        base16-lite = {
          syntax-theme = "base16";

          # Blame (<hash> <date> number:)
          blame-format = "${colors.pink}{commit:<8}${colors.reset} ${colors.blue}{timestamp:<10}${colors.reset}";
          blame-timestamp-output-format = "%Y-%m-%d";
          blame-separator-format = "{n:>4}| ";
          blame-separator-style = "brightblack";
          blame-code-style = "syntax";
          blame-palette = "normal black";

	  #File Header
          file-style = "bold yellow";
          file-decoration-style = "none";

	  # Hunk Header
          hunk-header-style = "omit-code-fragment";

          # Additions & Deletions
          minus-style = "red normal";
          plus-style = "green normal";
          zero-style = "normal";
          keep-plus-minus-markers = false;

          # Intra-line word changes
          minus-emph-style = "ul red normal";
          plus-emph-style = "ul green normal";

          # Line numbers & gutter
          line-numbers-minus-style = "red";
          line-numbers-plus-style = "green";
          line-numbers-zero-style = "brightblack";
          line-numbers-left-format = "{nm:>4}┊";
          line-numbers-right-format = "{np:>4}│";
          line-numbers-left-style = "brightblack";
          line-numbers-right-style = "brightblack";
        };
      };
    };

    # 4. GitHub CLI (gh)
    home.packages = [
      pkgs.gh
    ];
  };
}
