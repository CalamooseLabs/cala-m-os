{
  pkgs,
  config,
  ...
}: {
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };
  };

  hardware.graphics.extraPackages = with pkgs; [
    vulkan-loader
    vulkan-validation-layers
    vulkan-extension-layer
  ];

  services.xserver.videoDrivers = ["nvidia"];

  boot.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_drm"];

  boot.initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_drm"];
}
