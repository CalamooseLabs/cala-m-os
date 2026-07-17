{
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.programs.yubikey-github-bootstrap;
in {
  # The yubikey-github-bootstrap command ships from the antlers scripts
  # collection. This module keeps the `programs.yubikey-github-bootstrap` facade
  # (enable + the bot identity defaults) and delegates the install to
  # programs.antlers-scripts, which bakes the values in via makeWrapper.
  imports = [inputs.antlers.nixosModules.antlers-scripts];

  options.programs.yubikey-github-bootstrap = {
    enable = lib.mkEnableOption "the yubikey-github-bootstrap command (provision a Yubikey from scratch with an on-card OpenPGP GitHub identity, present-but-no-touch)";

    gpgName = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "OpenPGP user-ID name baked as the default (empty → git user.name / prompt).";
    };

    gpgEmail = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "OpenPGP user-ID email baked as the default; must be verified on the bot GitHub account (empty → git user.email / prompt).";
    };

    protonVault = lib.mkOption {
      type = lib.types.str;
      default = "Cala-M-OS";
      description = "Proton Pass vault the printed instructions tell you to store the public key in.";
    };

    protonItem = lib.mkOption {
      type = lib.types.str;
      default = "ai-github-gpg.asc";
      description = "Proton Pass item title for the public key (must match calamoose.secrets.<item>.itemTitle).";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.antlers-scripts = {
      enable = true;
      yubikey-github-bootstrap = {
        enable = true;
        gpgName = cfg.gpgName;
        gpgEmail = cfg.gpgEmail;
        protonVault = cfg.protonVault;
        protonItem = cfg.protonItem;
      };
    };
  };
}
