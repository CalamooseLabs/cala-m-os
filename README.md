<p align="center" style="font-size: 1.5em;">
  <i>Calamoose Labs Presents</i>
</p>
<p align="center">
  <img height="250px" src="./assets/cala-m-os_logo_large.png" alt="Logo" />
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

### Key Installation

#### GPG Signing key

1. Copy Yubikey's GPG secret key into home directory: `sudo cp /run/agenix/yubigpg.asc`

2. Change owner to self: `sudo chown ccalamos:users yubigpg.asc`

3. Import to GPG: `gpg --import yubigpg.asc`

4. Delete key: `rm yubigpg.asc`

#### SSH Keys

1. Go into SSH directory: `cd ~/.ssh`

2. Grab keys from Yubikey: `ssh-keygen -K`

3. Start ssh-agent: `eval "$(ssh-agent -s)"`

4. Add to ssh-agent: `ssh-add ~/.ssh/id_ed25519_sk_rk_it@calamos.family`

## License

Internal App is open-source software licensed under the MIT License.

<p align="right">
  <br />
  <br />
  <span>© 2025 Calamoose Labs, Inc.</span>&nbsp;<img src="./assets/logo.png" alt="Calamoose Labs Logo" height="15px">
</p>

Things to do:

- Make it so whatever user is the default, the name is "hub" but it inherits all behaviors
- Move any specific items to either machine (like internal display for laptop) [maybe we will have it pass the machine being used as well so it sets that up but also grabs any machine modules]
- Add modules for gpus into the machines
- Work on switcher to switch between Users
- Work on prefetch so install-cala-m-os will setup prefetch as well
- Side effects removed from all modules and machines
- moving non cala-m-os templates out to seperate private repo
