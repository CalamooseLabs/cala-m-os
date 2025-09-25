final: prev: {
  yubikey-manager = prev.yubikey-manager.overrideAttrs (oldAttrs: rec {
    version = "5.7.1";
    src = prev.fetchFromGitHub {
      owner = "Yubico";
      repo = "yubikey-manager";
      rev = version;
      hash = "sha256-WC74UldrUYpedSk0oSZJn+AdvJYsS/WWJaLYZ3OMqLo=";
    };
  });
}
