{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    vulkan-loader
    vulkan-tools
    vulkan-validation-layers
    (bottles.override {
      removeWarningPopup = true;
    })
  ];

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
}
