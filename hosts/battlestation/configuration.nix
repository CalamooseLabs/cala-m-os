##################################
#                                #
#   Gaming Desktop + Stream Src  #
#                                #
##################################
{cala-m-os, ...}: let
  import_users = ["gamer"];

  machine_type = "Workstation";
  machine_uuid = "B850-MAX";
in {
  calamoose.enableSecrets = false;
  calamoose.version = "2.2.0";
  calamoose.style = "thecompany"; # The Company, Inc. brand theme

  imports = [
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
        ];
      };
    })
  ];

  # Drop the built Cobblemon Initiative .mrpack in ~/TCI (or repoint mrpackPath at
  # a synced dist/ dir / file); the template rebuilds whenever the pack hash changes.
  # Firewall scoped to the studio subnet (where `broadcast`/Companion lives), so no
  # other device can spawn instances. battlestation (10.1.10.30) and broadcast
  # (10.1.10.15) share the studio subnet, so the button reaches :8778 intra-subnet.
  #
  # To lock the overlay's attempt/cemetery to the run counter, add:
  #   syncOverlay = true;
  #   overlayTokenFile = <the shared cobblemon-overlay token>;  # see the module README
  services.tci-run = {
    enable = true;
    allowedSources = ["${cala-m-os.ip.studio.subnet}"];
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
