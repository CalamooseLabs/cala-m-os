{
  config,
  pkgs,
  betaPkgsFor,
  ...
}: let
  # Beta-aware (the reference for the pattern): what this module installs comes
  # from `betaPkgsFor "obs-studio"` — the main nixpkgs normally, the
  # nixpkgs-beta input when a host or user profile sets
  # `calamoose.modules."obs-studio".beta = true` (see hosts/_core/options.nix;
  # the betaAware declaration below makes the flag loud when this module isn't
  # enrolled). Plain `pkgs` stays bound to the MAIN pin for
  # the driver-coupled exception below; a module with no such exception can
  # simply shadow (`pkgs = betaPkgsFor "<name>";` — see ./home.nix). Not
  # affected either way: the v4l2loopback kernel module comes from
  # config.boot.kernelPackages, and the kernel is never split across channels.
  # (programs.obs-studio assembles finalPackage with the main pin's wrapOBS —
  # a pure symlinkJoin+env wrapper, safe to mix.)
  obsPkgs = betaPkgsFor "obs-studio";
in {
  calamoose.modules."obs-studio".betaAware = true;

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
      baseObs = obsPkgs.obs-studio.override {
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
      obsPkgs.symlinkJoin {
        name = "obs-studio-nosync";
        paths = [baseObs];
        nativeBuildInputs = [obsPkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/obs --set __NV_DISABLE_EXPLICIT_SYNC 1
        '';
      };
    plugins = with obsPkgs.obs-studio-plugins; [
      wlrobs
      obs-aitum-multistream
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vertical-canvas
      obs-move-transition
      obs-source-record
      droidcam-obs
    ];
  };

  # DeckLink udev rules — deliberately the MAIN-pin `pkgs`, never obsPkgs.
  # hardware.decklink.enable does NOT install udev rules (it only ships the
  # DesktopVideoHelper systemd unit + the kernel driver, both from the main
  # pin), so this line is load-bearing — and Blackmagic strictly couples the
  # desktopvideo userspace to the driver version, so its rules must come from
  # the same channel as the driver (main 16.0 vs beta 16.3 at the time this
  # was split).
  services.udev.packages = [pkgs.blackmagic-desktop-video];

  # Open SRT port for camera streaming
  networking.firewall.allowedTCPPorts = [9998];
  networking.firewall.allowedUDPPorts = [9998];
}
