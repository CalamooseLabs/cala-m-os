# CALA-M-OS Installation Instructions

1. Download the Gnome Installer
   - Install normally and select the minimal install and reboot

2. Edit `/etc/nixos/configuration.nix` 
   - Add `git`, `vim` and `age-plugin-yubikey`
   - Add `services.pcscd.enable = true;`

3. Run `nixos-rebuild switch`

4. Copy `hardware-configuration.nix` to somewhere for safe keeping

5. Delete everything in `/etc/nixos/`

6. Grab the CALA-M-OS configuration `git clone https://github.com/calamooselabs/cala-m-os /etc/nixos/`

7. Copy `hardware-configuration.nix` back into `/etc/nixos`

8. Run `nixos-rebuild switch --flake .#CONFIGURATION`

9. Reboot
