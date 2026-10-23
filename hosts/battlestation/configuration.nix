##################################
#                                #
#   Gaming Desktop + Stream Src  #
#                                #
##################################
{
  lib,
  cala-m-os,
  initialInstallMode,
  ...
}: let
  import_users = ["gamer"];

  machine_type = "Workstation";
  machine_uuid = "B850-MAX";
in {
  calamoose.enableSecrets = false;
  calamoose.version = "3.0.0";
  calamoose.style = "thecompany"; # The Company, Inc. brand theme

  imports =
    [
      # Common Core Config
      (import ../_core/default.nix {
        users_list = import_users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
        extra_user_modules = {
          gamer = [
            "cobblemon-overlay"
            "davinci-resolve"
            "tci-run"
            "yazi"
          ];
        };
      })
    ]
    # The user modules above exist only in the full config, not the minimal
    # INITIAL_INSTALL_MODE pass, so their settings ride this conditional import:
    # an unguarded definition fails that pass with "option does not exist".
    ++ lib.optional (!initialInstallMode) {
      services.tci-run = {
        enable = true;
        allowedSources = ["${cala-m-os.ip.studio.subnet}"];
        syncOverlay = true;
        resetWipesInstances = true;
      };
    };

  networking.hostName = "battlestation";

  # Audio (PipeWire will handle the GPU's audio output)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
}
