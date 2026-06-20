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

**Cala-M-OS** is multiple NixOS configurations for workstations, laptops, servers, and VMs

> 📖 **Full technical documentation lives in the [Wiki](../../wiki)** (source under [`wiki/`](./wiki)): architecture, the configuration hierarchy, hosts, machines, modules, services, user switching, secrets, MicroVMs, and the installer — with Mermaid diagrams throughout.

---

## Features

- **One flake, many machines**: laptops, desktops, servers, SBCs, and MicroVMs all built from a single configuration.
- **Automated Setup**: Use `install-cala-m-os` for quick up and running.
- **Security Key Secrets**: Using Yubikeys as hardware security keys to allow for signing, ssh, gpg and secret encryption behind agenix/age.
- **MicroVM guests**: services like Plex and the media-automation suite run as declarative MicroVMs managed by their host.
- **Impermanence**: select hosts boot from a tmpfs root and persist only what's declared (via `preservation`).
- **Themed desktops**: Hyprland / niri sessions styled consistently through Stylix.

---

## Getting Started

### Cala-M-OS install

1. Run Custom ISO Build running `nix build .#nixosConfigurations.iso.config.system.build.isoImage`

2. On new computer boot into custom ISO installer and run `sudo install-cala-m-os <flake_name>`

3. Reboot

### Key Installation

Hosts that carry the `developer` profile (e.g. `viber`) ship two commands that
automate the steps below — these are **programs you run on demand**, not boot
services, since each needs the Yubikey + PIN (+ a touch). Run them once after a
fresh install:

```bash
gpg-key-import   # import the Yubikey GPG public key into your keyring
ssh-key-import   # download the Yubikey resident SSH keys into ~/.ssh
```

Both are idempotent and safe to re-run. The manual steps they replace are kept
below for hosts without the modules.

#### GPG Signing key(s) — manual

1. Copy Yubikey's GPG secret key into home directory: `sudo cp /run/agenix/yubigpg.asc ~/`

2. Change owner to self: `sudo chown hub:users yubigpg.asc`

3. Import to GPG: `gpg --import yubigpg.asc`

4. Delete key: `rm yubigpg.asc`

#### SSH Keys — manual

1. Go into SSH directory: `cd ~/.ssh`

2. Grab keys from Yubikey: `ssh-keygen -K`

3. Start ssh-agent: `eval "$(ssh-agent -s)"`

4. Rename to `id_ed25519_sk` & `id_ed25519_sk.pub`

5. Add to ssh-agent: `ssh-add ~/.ssh/id_ed25519_sk`

## Hosts

Hosts are built with `sudo nixos-rebuild switch --flake .#<host>`. Physical machines run
on real hardware; **MicroVM guests** run on a host through its `cala-vm-manager` service
(sizes defined under `machines/vms/`). Each host's `calamoose.version` is surfaced in
`nixos-version` and the boot-menu entry.

### Physical machines

| Host | Machine | User | Version | Role |
|------|---------|------|---------|------|
| `devbox` | Framework 16 (AMD, RTX 5070) | `debugger` | `2.1.0` | Main daily laptop — dev, printing, OBS |
| `battlestation` | AM5 desktop (B850) | `mixer` | `2.0.0` | Desktop workstation |
| `lanstation` | Intel desktop (B760) | `gamer` | `1.0.0` | LAN gaming station — NVIDIA VFIO passthrough |
| `broadcast` | Threadripper (TRX50-SAGE) | `streamer` | `1.0.0-beta` | Live stream box — RTX Pro 4000, Blackmagic Quad HDMI, OBS |
| `homelab` | Minisforum MS-02 | `server` | `2.0.0-beta` | Homelab VM host — runs `media` + `torrent` |
| `livedata` | Minisforum MS-01 | `server` | `1.0.0-alpha` | App/VM host — runs `openreturn` + `quorumcall` |
| `simple` | Framework 13 | `basic` | `1.0.0` | Minimal desktop setup |
| `viber` | Zima | `developer` | `0.0.1-alpha` | Headless TTY dev box — impermanent root |
| `ephemeral` | Zima | `void` | `0.0.1-beta` | Throwaway lab machine — impermanent root |

### MicroVM guests

| Guest | Size | User | Version | Runs on | Role |
|-------|------|------|---------|---------|------|
| `media` | Small | `server` | `0.9.0-beta` | `homelab` | Plex media server (Caddy SSL) |
| `torrent` | X-Small | `server` | `0.9.0-beta` | `homelab` | Radarr / Sonarr / Prowlarr + qBittorrent (VPN) |
| `openreturn` | Small | `server` | `0.1.0-alpha` | `livedata` | OpenReturn TTY app server |
| `quorumcall` | Small | `server` | `0.1.0-alpha` | `livedata` | QuorumCall TTY app server |
| `lanstation-vm` | Large | `gamer-vm` | `1.0.0` | `lanstation` | Per-seat gaming VM (`lanstation-2/3/4`) |
| `htpc` | Large | `gamer` | `0.0.1-beta` | — | Home theater PC (defined, not yet deployed) |
| `vault` | Small | `server` | `0.0.1-beta` | — | LanCache via Arion/Docker (defined, not yet deployed) |

> **Notes** — The `lanstation` family has three configs: `lanstation` (single-GPU
> station), `lanstation-multi` (TRX50 multi-GPU VM host serving `lanstation-1`…`4`), and
> `lanstation-vm` (the per-seat gaming guest). `openreturn` and `quorumcall` are also
> exposed as standalone flake outputs in addition to running as `livedata` guests. `iso`
> is the custom installer image (see [Getting Started](#getting-started)).

## Common Commands

```bash
# Rebuild and switch the current host
sudo nixos-rebuild switch --flake .#<host>

# Evaluate every host without building (catches option/eval errors)
nix flake check

# Format all Nix files
alejandra .

# Enter the dev shell (alejandra, nixd, nil, claude-code, …)
nix develop

# Build the installer ISO
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

## Architecture

Cala-M-OS is a single flake that builds everything from single-board computers to
laptops, workstations, servers, and VMs. Configuration flows top-down through a few
clearly-separated layers, each with one job.

### `flake.nix` + `settings.nix`

`flake.nix` is the entry point — it pins inputs, applies overlays, and declares every
machine via `mkSystem`. `settings.nix` holds global constants (default user, timezone,
network IPs, NFS paths) and is injected everywhere through `specialArgs` as `cala-m-os`.

### `hosts/` — the configurable machines

A host answers *"who and what is this machine?"* It picks its `users_list`, its
`machine_uuid` / `machine_type`, and any host-specific settings, then inherits the rest
from `hosts/_core`. Hosts are **hardware-agnostic** — the only exception is a VM host,
which needs to pass a device through to its guests. A host can also bolt extra modules
onto a user to expand that user's capabilities on that machine.

> Goal: eventually the machine ID and type become defaults that the installer can
> override, so a host file carries even less hardware knowledge.

### `machines/` — the hardware layer

Split into the two kinds of machines we build:

- `machines/workstations/<UUID>/` — **physical hardware.** Holds the
  `hardware-configuration.nix`, `disko.nix`, and whatever it takes to make *this* box
  work: hardware enablement plus module overrides (e.g. a Hyprland config targeting the
  machine's specific GPU and screen sizes).
- `machines/vms/<size>/` — **microvm definitions.** MicroVM is the only VM type used
  (no traditional virtual servers), parameterized by size (`X-Small` → `Large`).
- `machines/modules/` — reusable **hardware-enablement modules** (`amd-gpu`,
  `nvidia-gpu`, `intel-gpu`, `amd-cpu`). Imported by the workstation machine configs,
  not by hosts.

### `modules/` — programs

The lightweight layer: a program plus its settings, or a shell script. Each module has
an optional `configuration.nix` (system-level) and/or `home.nix` (home-manager).

### `services/` — the heavy, host-driven units

Larger pieces of infrastructure that are written the Nix-idiomatic way
(`services.<service>`) and are parameterized — they expect the host to supply the rest
of the settings (e.g. `caddy` reverse proxy, `vm-manager`, `certs`).

### `users/` — the people

Each user selects the modules/programs it wants and carries its own user-level settings,
inheriting shared defaults from `users/_core`.

### Supporting folders

- `iso/` — the custom installer image (`install-cala-m-os`).
- `templates/` — `nix flake new` scaffolds for a new host, module, user, or secret.
- `overlays/`, `prefetch/`, `assets/` — package overrides, vendored blobs, and branding.

## License

Cala-M-OS is open-source software licensed under the MIT License.

<p align="right">
  <br />
  <br />
  <span>© 2026 Calamoose Labs, Inc.</span>&nbsp;<img src="./assets/logo.png" alt="Calamoose Labs Logo" height="15px">
</p>
