##################################
#                                #
#   Gaming Desktop + Stream Src  #
#                                #
##################################
{
  inputs,
  cala-m-os,
  lib,
  initialInstallMode,
  ...
}: let
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
  # Go-live reset: `tci-run reset` zeroes the counter, wipes the spawned
  # 'TCI - Run #N' tiles (+ empties the 'TCI Runs' group), and tells the
  # cobblemon-overlay to wipe its attempt/campaign/cemetery in one shot.
  # syncOverlay also locks the overlay's attempt number to the run counter after
  # every `new`. The overlay's /control is unauthenticated but firewall-pinned to
  # battlestation/32 (see modules/cobblemon-overlay), so no bearer token is wired;
  # add `overlayTokenFile = <shared token>;` (== services.cobblemon-overlay.tokenFile)
  # if you later want bearer auth as well.
  services.tci-run = {
    enable = true;
    allowedSources = ["${cala-m-os.ip.studio.subnet}"];
    syncOverlay = true;
    resetWipesInstances = true;
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
