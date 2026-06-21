{
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.programs.github-repo-puller;
in {
  # github-repo-puller now ships from the antlers scripts collection. This module
  # keeps the `programs.github-repo-puller` facade (enable + repos) and delegates
  # the install to antlers. hosts/ai reads `.repos` to persist the clone dirs, so
  # the option must stay defined here.
  imports = [inputs.antlers.nixosModules.antlers-scripts];

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
    programs.antlers-scripts = {
      enable = true;
      github-repo-puller = {
        enable = true;
        repos = cfg.repos;
      };
    };
  };
}
