{lib, ...}: {
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 3 --keep-since 3d";
    };
    flake = "/etc/nixos";
  };

  nix.gc.automatic = lib.mkForce false;
}
