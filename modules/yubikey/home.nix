{pkgs, ...}: {
  # Add the overlay to downgrade yubikey-manager
  nixpkgs.overlays = [
    (final: prev: {
      yubikey-manager = prev.yubikey-manager.overrideAttrs (oldAttrs: rec {
        version = "5.5.1";
        src = prev.fetchFromGitHub {
          owner = "Yubico";
          repo = "yubikey-manager";
          rev = version;
          hash = "sha256-WYrLaAI0BHpu4aKW5EHkVz8uJ0wMNJdWXLmtaan9t1M=";
        };
      });
    })
  ];

  home.packages = with pkgs; [
    yubioath-flutter
  ];
}
