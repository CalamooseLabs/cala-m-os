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
    package = let
      baseObs = pkgs.obs-studio.override {
        decklinkSupport = true;
        cudaSupport = true;
      };
    in
      # NVIDIA's EGL explicit-sync path (wp_linux_drm_syncobj) commits a
      # wl_surface with no acquire point set, which Hyprland/niri reject with
      # a fatal Wayland protocol error — crashing OBS when a projector opens
      # (and on capture-source teardown). Disabling explicit sync for OBS only
      # is the upstream-attested fix (obsproject/obs-studio#11022, #12007).
      # Vendor-agnostic and OBS-scoped, so it's safe across devbox (Hyprland,
      # plain obs) and broadcast (the obs-kiosk PRIME wrapper execs finalPackage).
      pkgs.symlinkJoin {
        name = "obs-studio-nosync";
        paths = [baseObs];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/obs --set __NV_DISABLE_EXPLICIT_SYNC 1
        '';
      };
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-aitum-multistream
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vertical-canvas
      droidcam-obs
    ];
  };

  # udev rules (already included by hardware.decklink.enable, but doesn't hurt)
  services.udev.packages = [pkgs.blackmagic-desktop-video];

  # Open SRT port for camera streaming
  networking.firewall.allowedTCPPorts = [9998];
  networking.firewall.allowedUDPPorts = [9998];
}
