{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.github-repo-puller;

  repoMap =
    lib.concatStringsSep "\n"
    (lib.mapAttrsToList (ref: dir: "${ref} ${dir}") cfg.repos);

  puller = pkgs.writeShellApplication {
    name = "github-repo-puller";
    runtimeInputs = with pkgs; [git curl jq coreutils];
    text = ''
      if [ "$(id -u)" -eq 0 ]; then
        echo "Run github-repo-puller as your user, not root — the clones must be owned by you." >&2
        exit 1
      fi

      REPO_MAP=${lib.escapeShellArg repoMap}
      ${builtins.readFile ./github-repo-puller.sh}
    '';
  };
in {
  options.programs.github-repo-puller = {
    enable = lib.mkEnableOption "the github-repo-puller command (clone/fast-forward configured GitHub repos on demand)";

    repos = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {"github:CalamooseLab/OpenReturn" = "/home/hub/nkc";};
      description = ''
        Map of "github:Owner[/Repo]" to the parent folder to clone into.
        "github:Owner/Repo" clones into <folder>/Repo; "github:Owner" clones
        every public repo of the owner into <folder>/<repo>.

        These repos are baked into the `github-repo-puller` command. Run it
        manually to clone or fast-forward them — nothing happens at boot.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [puller];
  };
}
