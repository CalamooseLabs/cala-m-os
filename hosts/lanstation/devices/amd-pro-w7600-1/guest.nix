{...}: {
  imports = [../../../../machines/modules/amd-gpu/configuration.nix];

  # Early KMS for the passthrough guest: the amd-gpu module no longer forces
  # amdgpu into the initrd (it wedged broadcast's stage-1), so opt in here to
  # keep this guest's previous behavior — with the GPU passed through, early
  # amdgpu gets the VM display up before switch-root.
  boot.initrd.kernelModules = ["amdgpu"];

  microvm.devices = [
    {
      bus = "pci";
      path = "0000:85:00.0"; # Pro W7600
    }
    {
      bus = "pci";
      path = "0000:85:00.1"; # Pro W7600 Audio
    }
  ];
}
