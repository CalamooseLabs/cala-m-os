##################################
#                                #
#        Home Theater PC         #
#                                #
##################################
{lib, ...}: let
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

  services.xserver.enable = false;

  # microvm.hypervisor = lib.mkForce "cloud-hypervisor";
  microvm.hypervisor = "qemu";

  microvm.qemu = {
    machine = "pc-q35-4.2,accel=kvm";
    extraArgs = [
      "-global"
      "ICH9-LPC.disable_s3=1"
      "-global"
      "ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off"
    ];
  };
}
