{
  pkgs,
  config,
  ...
}: {
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
    decklink
  ];
  boot.kernelModules = ["v4l2loopback" "blackmagic"];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  environment.systemPackages = [pkgs.blackmagic-desktop-video];

  # udev rules so DeckLink devices are accessible without root
  services.udev.packages = [pkgs.blackmagic-desktop-video];

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-pipewire-audio-capture
      droidcam-obs
      obs-multi-rtmp
    ];
  };

  # Open SRT port for camera streaming
  networking.firewall.allowedTCPPorts = [9998];
  networking.firewall.allowedUDPPorts = [9998];
}
