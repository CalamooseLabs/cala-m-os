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
      extra_user_modules = {gamer = ["davinci-resolve"];};
    })

    # TCI Run — Stream Deck "new hardcore run" PrismLauncher spawner. Host-scoped
    # (imported directly, not via the shared gamer profile) so lanstation's gamer
    # is untouched. Companion on `broadcast` fires GET http://10.10.10.30:8778/new-run.
    ../../modules/tci-run/configuration.nix
  ];

  # Drop the built Cobblemon Initiative .mrpack in ~/TCI (or repoint mrpackPath at
  # a synced dist/ dir / file); the template rebuilds whenever the pack hash changes.
  # Firewall scoped to the studio subnet (where `broadcast`/Companion lives), so no
  # other lab-subnet device can spawn instances. NOTE: studio↔lab is inter-VLAN —
  # the router must permit 10.1.10.0/26 → 10.10.10.30:8778 for the button to reach.
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
