{...}: {pkgs, ...}: {
  # Browser on this ephemeral lab box is the antlers `chromium-ephemeral`
  # (throwaway profile), enabled via the "chromium" module in ./default.nix.
  # Replaced programs.librewolf — its pinned build was flagged insecure, and a
  # throwaway-profile browser fits an impermanent machine. (The old librewolf
  # force-installed a teleprompter-mirror Firefox addon; chromium can't, so that
  # browser overlay is dropped — the standalone `teleprompter` app still ships.)
  home.packages = [
    pkgs.usbutils
    pkgs.pciutils
  ];
}
