{...}: {pkgs, ...}: {
  home.packages = [
    pkgs.usbutils
    pkgs.pciutils
  ];

  programs.librewolf = {
    enable = true;
    policies = {
      ExtensionSettings = {
        "{8098af5e-6cd0-48df-9870-60be72d7089a}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/teleprompter-mirror/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };
}
