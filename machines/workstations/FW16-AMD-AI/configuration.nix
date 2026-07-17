##################################
#                                #
#     Framework 16 AMD Laptop    #
#                                #
##################################
{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    # Hardware Config
    ./hardware-configuration.nix
    ./disko.nix
    inputs.nixos-hardware.nixosModules.framework-16-amd-ai-300-series-nvidia

    # Modules
    ../../modules/nvidia-gpu/configuration.nix
  ];

  # Power saver for laptops
  networking.networkmanager.wifi.powersave = true;

  # Framework BIOS updates
  services.fwupd = {
    enable = true;
    extraRemotes = ["lvfs-testing"];
    uefiCapsuleSettings.DisableCapsuleUpdateOnDisk = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Nvidia 5070
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  boot.kernelParams = [
    "nvidia-drm.modeset=1"

    # GPU hard-freeze mitigations — see the 2026-07 diagnosis of the
    # intermittent full-machine freeze (top-down wipe -> black w/ artifacts).
    # Only take effect on the next rebuild + reboot; runtime equivalents are
    # applied by hand until then (amdgpu params are read-only at runtime).
    #
    # Disable CWSR on the Strix 890M (gfx1150): the known compute-wavefront
    # save/restore hard-hang class, otherwise un-mitigated (module default = 1).
    "amdgpu.cwsr_enable=0"
    # Attempt a *logged* GPU reset on a ring hang instead of silently wedging
    # the whole machine — also gives us a trace to work from (default -1/auto).
    "amdgpu.gpu_recovery=1"
  ];

  services.pipewire.wireplumber.extraConfig.no-ucm = {
    "monitor.alsa.properties" = {
      "alsa.use-ucm" = false;
    };
  };

  hardware.enableAllFirmware = true;

  # Enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.logind.settings.Login.HandleLidSwitch = "ignore";

  #############################################################################
  # GPU hard-freeze mitigations (2026-07 diagnosis)                           #
  #                                                                           #
  # Intermittent whole-machine freeze after long screen-on periods: a         #
  # top-down "wipe" -> black with white artifacts -> total lock, nothing left #
  # in the journal. Two live suspects: (A) amdgpu DCN3.5 display-pipe hang on  #
  # the internal panel, (B) the RTX 5070 (Blackwell) dGPU's D3cold resume     #
  # race. Firmware disables PCIe AER so faults leave no trace -> also arm      #
  # crash capture. Inert until the next rebuild + reboot.                      #
  #############################################################################

  # Suspect B (leading, un-mitigated): stop the RTX 5070 (PCI 0000:c2:00.0)
  # from entering D3cold, whose cold-resume on this brand-new silicon is the
  # prime freeze suspect. Blocking only D3cold keeps the lighter D3hot runtime
  # suspend, so idle battery drain barely moves (traveling-friendly). If
  # freezes persist, escalate this to ATTR{power/control}="on" (never suspends).
  # Merges with the Optix-drive rule in hosts/devbox/configuration.nix.
  services.udev.extraRules = ''
    ACTION=="add|bind", SUBSYSTEM=="pci", KERNEL=="0000:c2:00.0", ATTR{d3cold_allowed}="0"
  '';

  # Crash capture: turn a hard-lockup / oops into a panic that auto-reboots, so
  # the fatal trace lands in efi-pstore and survives the power-cycle. Read it
  # after a freeze with:  sudo cat /sys/fs/pstore/dmesg-efi-*
  # Deliberately NOT enabling softlockup_panic — it would false-fire under heavy
  # nix builds. sysrq=1 allows a manual SysRq-c crash if the box is semi-alive.
  boot.kernel.sysctl = {
    "kernel.hardlockup_panic" = 1;
    "kernel.panic_on_oops" = 1;
    "kernel.panic" = 20;
    "kernel.sysrq" = 1;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
