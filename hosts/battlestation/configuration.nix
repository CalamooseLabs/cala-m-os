##################################
#                                #
#   Gaming Desktop + Stream Src  #
#                                #
##################################
{...}: let
  import_users = ["gamer"];

  machine_type = "Workstation";
  machine_uuid = "B850-MAX";
in {
  calamoose.enableSecrets = false;
  calamoose.version = "2.0.1";

  imports = [
    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {};
    })
  ];

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
