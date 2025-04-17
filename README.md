<p align="center" style="font-size: 1.5em;">
  <i>Calamoose Labs Presents</i>
</p>
<p align="center">
  <img height="250px" src="./assets/cala-m-os_logo.png" alt="Logo" />
</p>
<h1 align="center" style="color: gold;">
  <u>C A L A - M - O S</u>
  <br />
  <br />
</h1>

**Cala-M-OS** is a NixOS configuration for workstations and servers.

---

## Features

- **Hyprland**: For productivity and window management.
- **Split Users**: Keep in the flow with the current user task.
- **Automated Setup**: Use `install-cala-m-os` for quick up and running.
- **Security Key Secrets**: Using Yubikeys as hardware security keys to allow for signing, ssh, gpg and secret encryption behind agenix/age.

---

## Getting Started

### CALA-M-OS Installation Instructions

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

### Disko install

1. Run Custom ISO Build running `nix flake build`

2. On new computer boot into custom ISO installer and run `install-cala-m-os`

3. Reboot

## License

Internal App is open-source software licensed under the MIT License.

<p align="right">
  <br />
  <br />
  <span>© 2024 Calamoose Labs, Inc.</span> &nbsp; <img src="./assets/logo.png" alt="Calamoose Labs Logo" height="15px">
</p>
