# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

**Cala-M-OS** is a multi-host NixOS flake configuration managing workstations, servers, VMs, and a custom installer ISO. The flake defines 14 host outputs: `lanstation`, `devbox`, `ephemeral`, `homelab`, `simple`, `battlestation`, `broadcast`, `openreturn`, `livedata`, `ai`, `tci-cloud`, `tci-private`, `webhost` (the only aarch64 host), and `iso`. Several other host directories are microVM **guests** (`media`, `torrent`, `lanstation-vm`, `htpc`, `vault`, plus `quorumcall`) that a parent host builds via its `vms.nix` — they are not top-level outputs. Note: `lab` and `studio` are **subnet names** in `settings.nix`, not hosts.

## Common Commands

```bash
# Rebuild and switch current host
sudo nixos-rebuild switch --flake .#<hostname>

# Rebuild with verbose output / show trace on error
sudo nixos-rebuild switch --flake .#<hostname> --show-trace

# Format Nix files
alejandra .

# Check flake for errors
nix flake check

# Enter dev shell (provides alejandra, nixd, nil, claude-code)
nix develop

# Build the custom installer ISO
nix build .#nixosConfigurations.iso.config.system.build.isoImage

# Build the RAM-only installer that `sudo cala-reinstall` kexecs a running host into
# (every physical host has cala-reinstall; -vm = without linux-firmware, for VMs/cloud;
# the same two exist under packages.aarch64-linux for webhost)
nix build .#installer-kexec
nix build .#installer-kexec-vm

# The live installer's tools (cala-installer TUI + token-aware install-cala-m-os), the
# package the TUI's "Update the installer" pulls from the flake onto an old stick
nix build .#installer-tools

# Install on new hardware (run from ISO)
INITIAL_INSTALL_MODE=1 sudo nixos-install --flake .#<hostname>
```

## Architecture

### Configuration Hierarchy

Configurations flow top-down through layers of abstraction:

```
flake.nix  (mkSystem → 13 host outputs; iso + installer-kexec{,-vm}{,-aarch64} built directly)
  └── hosts/<hostname>/configuration.nix  (host-specific params: users_list, machine_uuid, machine_type)
        └── hosts/_core/default.nix  (parameterized common config — imports core + machine + users)
              ├── hosts/_core/configuration.nix  (boot, networking, GC, greetd, firewall, timezone)
              ├── hosts/_core/home.nix  (home-manager entry point)
              ├── machines/workstations/<UUID>/configuration.nix  (hardware-specific)
              └── users/<username>/default.nix  (user profile → imports modules)
```

### Module System

Modules live in `modules/<name>/` and ship **both** files (one may be a near-empty stub):
- `configuration.nix` — NixOS system-level config
- `home.nix` — Home-manager user config

Users opt into modules by bare name in the `modules` list in `users/<username>/default.nix`. The `debugger` user (used by devbox) is the most comprehensive with ~63 modules. Not every module is enrolled by a user — some are kept as an intentional "available/shelf" set.

### Key Files

| File | Purpose |
|------|---------|
| `flake.nix` | Entry point; defines inputs, overlays, and all host outputs |
| `settings.nix` | Global constants (user, timezone, network IPs, NFS paths) injected via `specialArgs` as `cala-m-os` |
| `hosts/_core/default.nix` | Parameterized core config; imports machine + user layers |
| `hosts/_core/non-vm.nix` | Workstation-only settings (unfree, auto-optimize, activation scripts) |
| `machines/workstations/<UUID>/` | Per-machine hardware config, disko layout, and home config |
| `machines/vms/_core/` | Base VM config (microvm.nix/QEMU, parameterized by cores/memory) |

### Hosts

Flake outputs (built with `nixos-rebuild ... --flake .#<host>`):

| Host | Machine | Primary User | Notes |
|------|---------|-------------|-------|
| `devbox` | FW16-AMD-AI | `debugger` | Framework 16 daily laptop; builds/tests modules; printing |
| `simple` | FW13-12XXP | `basic` | Minimal privacy laptop for family |
| `ai` | ZIMA | `developer` | Headless TTY dev box (impermanent); runs background Claude sessions |
| `ephemeral` | ZIMA | `void` | Throwaway impermanent test box (niri) |
| `battlestation` | B850-MAX | `gamer` | Gaming desktop + stream source |
| `lanstation` | B760-PLUS | `gamer` | RTX 5090 host; VFIO — splits into a GPU-passthrough gaming VM (WIP) |
| `broadcast` | TRX50-SAGE | `streamer` | OBS live-stream box; RTX Pro 4000 + AMD GPU (evdi teleprompter); `enableSecrets="online"` (Proton Pass: admin_password + multichat youtube-api-key) |
| `homelab` | MS-02 | `server` | Homelab VM host (media + torrent + security); owns agenix secrets + cala-certs |
| `livedata` | MS-01 | `server` | Client app/VM host (openreturn + quorumcall); `enableSecrets=false` |
| `openreturn` | Small VM | `server` | OpenReturn app; standalone output *and* a `livedata` guest |
| `tci-cloud` | HETZNER-CLOUD | `server` | The Cobblemon Initiative public hub fleet on a Hetzner Cloud CCX (x86 VM). `enableSecrets=false`; the private `cobblemon-initiative` input means deploys run as root on devbox (nixos-anywhere / `nixos-rebuild --target-host`, steps in its header) |
| `tci-private` | TCI-LOCAL | `server` | The Cobblemon Initiative soul-link fleet on a LAN box; static lab IP |
| `webhost` | HETZNER-CAX | `webmaster` | Minimal public web server on a Hetzner Cloud CAX11 (**aarch64**, EU-only). Caddy auto-HTTPS serves each module under `hosts/webhost/sites/<site>/`. `enableSecrets=false`. Deployed from devbox and built on the box (`--build-host`); deploy steps are in its header |
| `iso` | — | — | Custom installer with disko + agenix |

**microVM guests** (built by a parent host's `vms.nix`, not top-level outputs): `media` (Medium) + `torrent` (X-Small) + `security` (X-Small, UniFi Protect camera wall) on `homelab`; `openreturn` + `quorumcall` (Small) on `livedata`; `lanstation-vm` (Large, the gaming guest) on `lanstation` (WIP). `htpc` and `vault` (local Steam cache) are defined but not yet wired to a parent.

### Hetzner Cloud hosts + reinstall-in-place

- `machines/modules/hetzner-cloud` is shared by the `HETZNER-CLOUD` and `HETZNER-CAX` machines: systemd-networkd for Hetzner's **routed (Layer 3)** network — IPv4 over Hetzner's DHCP (a /32 behind the off-subnet gateway 172.31.1.1, which networkd handles) until the host sets `calamoose.hetznerCloud.ipv4Address` (then DHCP is off and the /32 + on-link default route are static); IPv6 only via `ipv6Address` (Hetzner configures IPv6 statically and no router advertisements are documented or observed; gateway `fe80::1`); Hetzner's resolvers on both paths; `qemu-guest` profile + guest agent (Console password reset); visible boot menu, no Plymouth (web-console only). Hosts set the addresses inside their `lib.optional (!initialInstallMode)` block because the module (and its options) is not part of the minimal install pass. First installs run on DHCP (addresses unknown); fill them in afterwards, and publish AAAA records only once `curl -6` works.
- Both Hetzner hosts are first installed with **nixos-anywhere from Hetzner's Rescue system** (steps in each host's header). `install-cala-m-os` can't auto-wipe them (`wipeAllDisks` needs a by-id pin and the root disk's by-id name varies between Hetzner servers), so the installer TUI runs disko interactively for such hosts (it asks for a typed `yes`) and then installs with `INSTALL_SKIP_DISKO=1`. CPX/CCX/CAX servers boot UEFI (what the disko layouts assume); the CX line is legacy BIOS.
- **`cala-reinstall` is on every physical host** (`hosts/_core/non-vm.nix`; microVM guests are rebuilt by their parent instead): `sudo cala-reinstall` kexecs the running host into the RAM-only installer. Flake outputs `installer-kexec` (with linux-firmware, bare metal) and `installer-kexec-vm` (without, ~half the size — fits a 4 GB cloud VM) exist for x86_64 and aarch64 (`packages.<system>`); `cala-reinstall` picks `vm` under `systemd-detect-virt` (`--variant`). The installer image builds antlers' scripts by calling `pkgs.callPackages` on antlers' `flakes/scripts/package.nix` (and `callPackage` on `flakes/proton-secrets/package.nix`) against its own package set — not antlers' x86_64-only `packages.<system>`, and not its overlay, whose attribute names depend on `final` and recurse inside nixpkgs — which is what lets the aarch64 image exist. It exports `CALA_INSTALLER_HOSTS/_MACHINES/_VM_MACHINES` (computed from the flake) for the TUI's pickers, which also refresh from the flake once online. `iso/tools.nix` holds those tools as plain derivations and the flake exposes them as `packages.<system>.installer-tools`: the TUI's **"Update the installer"** entry builds that from the flake it installs from and re-executes itself from the result (PATH-first), so an old ISO/stick runs today's installer without reflashing; the image exports `CALA_INSTALLER_MEDIA_DIR` so the pulled `cala-nix-token` still finds this image's PAT.

### Secrets / Security

- **agenix** manages secrets encrypted to Yubikey-backed SSH keys. Decryption cannot happen at activation time (pcscd is not up yet), so `modules/agenix` ships `agenix-rerun.service`; anything that needs a secret at boot orders after it (`services/vm-manager`, `services/certs`, `modules/vpn`)
- **GPG** and **Yubikey** modules handle hardware key integration
- The ISO boots with Yubikey SSH auth; installs using `INITIAL_INSTALL_MODE=1` for a minimal first pass, then does a full rebuild
- `homelab` and its guests rebuild from scratch via `wiki/Disaster-Recovery.md`: guest state comes back through `calamoose.install.firstBootCommands` restores (plex/radarr/sonarr/prowlarr/qbittorrent) from the NAS backup shares

### specialArgs Pattern

Global config (`settings.nix`) is available throughout the tree as `cala-m-os`:

```nix
# Access in any module
{ cala-m-os, ... }:
cala-m-os.globals.defaultUser  # "hub"
cala-m-os.globals.TZ           # "America/Denver"
cala-m-os.ip.lab.gateway       # "10.10.10.1"
```

### Beta Channel (staged upgrades)

Two nixos-unstable pins: `nixpkgs` (the system) and `nixpkgs-beta` (rides ahead).
`nix flake update nixpkgs-beta` bumps ONLY beta; the system pin stays put. Per-host opt-in:

- `calamoose.beta.packages = ["obs-studio"];` — swap single **top-level** attrs host-wide (an overlay, so it reaches home-manager too via `useGlobalPkgs`). Nested attrs need an explicit overlay.
- `calamoose.modules."<name>".beta = true;` — flip a **beta-aware** cala module wholesale (set from a host or a user profile; host-global either way). The option set is generated from the `modules/` directory listing, so a typo'd name fails eval. A module opts in by taking `betaPkgsFor` in its args, selecting `pkgs = betaPkgsFor "<name>";` in both `configuration.nix` and `home.nix`, and declaring `calamoose.modules."<name>".betaAware = true;` (reference: `modules/obs-studio`). Flipping a module that isn't beta-aware (or isn't enrolled) emits an eval warning. Kernel bits (`config.boot.*`) always stay on the main pin.

Graduate by bumping the main `nixpkgs` and clearing the beta lists. Options + assertions live in `hosts/_core/options.nix`.

### Adding a New Module

1. Scaffold from the template: `nix flake init -t .#module` (or create `modules/<name>/` by hand)
2. Provide **both** `modules/<name>/configuration.nix` and `modules/<name>/home.nix` (stub the unused one)
3. `git add` the new files before evaluating, then opt in by adding the bare `<name>` to the `modules` list of the relevant user profile(s) in `users/<username>/default.nix`

### Adding a New Host

1. Scaffold from the template: `nix flake init -t .#host` (or create `hosts/<hostname>/configuration.nix` by hand), specifying `users_list`, `machine_uuid`, `machine_type`. Import `../_core/default.nix` (the wrapper that adds the `initialInstallMode` installer branch), **not** `../_core/configuration.nix` directly.
2. Add to `flake.nix` under `nixosConfigurations` using `mkSystem`
3. Add machine hardware config under `machines/workstations/<UUID>/` if it's new hardware (resolved via `machines/resolve.nix`). Its `hardware-configuration.nix` owns `nixpkgs.hostPlatform`, and that wins over mkSystem's x86 `system` fallback. This is how `HETZNER-CAX` makes `webhost` aarch64.
4. For a microVM **guest** instead of a top-level host, declare it in a parent host's `vms.nix` rather than adding a `mkSystem` output
