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

**Cala-M-OS** is multiple NixOS configurations for workstations, servers, and VMs.

---

## Features

- **Hyprland**: For productivity and window management on majority of hosts.
- **Split Users**: Keep in the flow with the current user task.
- **Automated Setup**: Use `install-cala-m-os` for quick up and running.
- **Security Key Secrets**: Using Yubikeys as hardware security keys to allow for signing, ssh, gpg and secret encryption behind agenix/age.
- **Offline Work**: Works offline as well

---

## Getting Started

### Cala-M-OS install

1. Run Custom ISO Build running `nix build .#nixosConfigurations.iso.config.system.build.isoImage`

2. On new computer boot into custom ISO installer and run `sudo install-cala-m-os <flake_name>`

3. Reboot

### Key Installation

#### GPG Signing key(s)

1. Copy Yubikey's GPG secret key into home directory: `sudo cp /run/agenix/yubigpg.asc`

2. Change owner to self: `sudo chown ccalamos:users yubigpg.asc`

3. Import to GPG: `gpg --import yubigpg.asc`

4. Delete key: `rm yubigpg.asc`

#### SSH Keys

1. Go into SSH directory: `cd ~/.ssh`

2. Grab keys from Yubikey: `ssh-keygen -K`

3. Start ssh-agent: `eval "$(ssh-agent -s)"`

4. Rename to `id_ed25519_sk` & `id_ed25519_sk.pub`

5. Add to ssh-agent: `ssh-add ~/.ssh/id_ed25519_sk_rk_it@calamos.family`

## License

Cala-M-OS is open-source software licensed under the MIT License.

<p align="right">
  <br />
  <br />
  <span>© 2025 Calamoose Labs, Inc.</span>&nbsp;<img src="./assets/logo.png" alt="Calamoose Labs Logo" height="15px">
</p>
