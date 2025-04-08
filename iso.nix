{
  pkgs,
  lib,
  configName,
  ...
}: let
  flake = builtins.getFlake (toString ./..);
in {
  isoImage = {
    isoName = "cala-m-os-${configName}-installer";
    isoLabel = "CALA_M_OS_${lib.strings.toUpper configName}";
    isoDescription = "Cala-M-OS Installer for ${configName}";

    configuration = {
      imports = [
        flake.outputs.nixosConfigurations.${configName}
      ];

      environment.systemPackages = with pkgs; [
        disko-install
        git
        vim
        age
        age-plugin-yubikey
      ];

      systemd.services.welcome-message = {
        description = "Show welcome message on boot";
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          ExecStart = "/bin/echo 'Welcome to the Cala-M-OS Installer for ${configName}! Run disko-install to install.'";
          Type = "oneshot";
        };
      };

      environment.etc."nixos-flake".source = ./..;
      environment.etc."nixos-flake".mode = "0755";
    };
  };
}
