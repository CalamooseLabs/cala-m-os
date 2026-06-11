{
  pkgs,
  config,
  ...
}: {
  hardware.decklink.enable = true;

  # v4l2loopback for virtual camera
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];
  boot.kernelModules = ["v4l2loopback"];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  # OBS with decklink support enabled
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    package = pkgs.obs-studio.override {
      decklinkSupport = true;
    };
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      droidcam-obs
      obs-multi-rtmp
    ];
  };

  # udev rules (already included by hardware.decklink.enable, but doesn't hurt)
  services.udev.packages = [pkgs.blackmagic-desktop-video];

  # Open SRT port for camera streaming
  networking.firewall.allowedTCPPorts = [9998];
  networking.firewall.allowedUDPPorts = [9998];
}
