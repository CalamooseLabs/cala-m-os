{pkgs, ...}: {
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      open = true;
      nvidiaSettings = true;
    };
  };

  hardware.graphics.extraPackages = with pkgs; [
    vulkan-loader
    vulkan-validation-layers
    vulkan-extension-layer
  ];

  services.xserver.videoDrivers = ["nvidia"];

  boot.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_drm"];

  # boot.kernelParams = ["nvidia-drm.modeset=1"];

  boot.initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_drm"];
}
