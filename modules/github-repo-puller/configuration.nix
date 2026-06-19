{
  config,
  pkgs,
  lib,
  cala-m-os,
  ...
}: let
  cfg = config.services.github-repo-puller;
  owner = cala-m-os.globals.defaultUser;

  repoMap =
    lib.concatStringsSep "\n"
    (lib.mapAttrsToList (ref: dir: "${ref} ${dir}") cfg.repos);

  puller = pkgs.writeShellApplication {
    name = "github-repo-puller";
    runtimeInputs = with pkgs; [git curl jq coreutils];
    text = ''
      REPO_MAP=${lib.escapeShellArg repoMap}
      ${builtins.readFile ./github-repo-puller.sh}
    '';
  };
in {
  options.services.github-repo-puller = {
    enable = lib.mkEnableOption "clone configured GitHub repos into chosen folders";

    repos = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {"github:CalamooseLab/OpenReturn" = "/home/hub/nkc";};
      description = ''
        Map of "github:Owner[/Repo]" to the parent folder to clone into.
        "github:Owner/Repo" clones into <folder>/Repo; "github:Owner" clones
        every public repo of the owner into <folder>/<repo>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [puller];

    systemd.services.github-repo-puller = {
      description = "Clone configured GitHub repos (idempotent oneshot)";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        User = owner;
        Group = "users";
        ExecStart = lib.getExe puller;
      };
    };
  };
}
