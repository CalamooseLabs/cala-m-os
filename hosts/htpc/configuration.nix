##################################
#                                #
#        Home Theater PC         #
#                                #
##################################
{
  lib,
  cala-m-os,
  ...
}: let
  import_users = ["gamer"];

  machine_type = "VM";
  machine_uuid = "Large";
in {
  imports = [
    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })
  ];

  networking.hostName = "htpc";

  # Audio Control
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Plasma 6
  services = {
    displayManager = {
      sddm.enable = true;
      autoLogin = {
        enable = true;
        user = cala-m-os.globalDefaultUser;
      };
    };
    desktopManager.plasma6.enable = true;
  };

  # Disable screen locking via systemd-logind
  services.logind.lidSwitch = "ignore";
  services.logind.extraConfig = ''
    IdleAction=ignore
  '';

  services.xserver.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.greetd.enable = lib.mkForce false;
}
