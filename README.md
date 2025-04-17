# CALA-M-OS Installation Instructions

1. Download the Gnome Installer

   - Install normally and select the minimal install and reboot

2. Run `nix-shell -p git`

3. Copy `hardware-configuration.nix` to somewhere for safe keeping

4. Delete everything in `/etc/nixos/`

5. Grab the CALA-M-OS configuration `git clone https://github.com/calamooselabs/cala-m-os /etc/nixos/`

6. Copy `hardware-configuration.nix` back into `/etc/nixos`

7. Run `nixos-rebuild switch --flake .`

8. Run `nixos-rebuild switch --flake .#calamooselabs`

9. Reboot

## Disko install

1. Run Custom ISO Build running `nix flake build`

2. On new computer boot into custom ISO installer and run `install-cala-m-os`

3. Reboot
