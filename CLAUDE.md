# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

**Cala-M-OS** is a multi-host NixOS flake configuration managing workstations, servers, VMs, and a custom installer ISO. The flake defines 11 host outputs: `lanstation`, `devbox`, `ephemeral`, `homelab`, `simple`, `battlestation`, `broadcast`, `openreturn`, `livedata`, `ai`, and `iso`. Several other host directories are microVM **guests** (`media`, `torrent`, `lanstation-vm`, `htpc`, `vault`, plus `quorumcall`) that a parent host builds via its `vms.nix` — they are not top-level outputs. Note: `lab` and `studio` are **subnet names** in `settings.nix`, not hosts.

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

# Install on new hardware (run from ISO)
INITIAL_INSTALL_MODE=1 sudo nixos-install --flake .#<hostname>
```

## Architecture

### Configuration Hierarchy

Configurations flow top-down through layers of abstraction:

```
flake.nix  (mkSystem → 10 host outputs; iso built directly)
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
| `homelab` | MS-02 | `server` | Homelab VM host (media + torrent); owns agenix secrets + cala-certs |
| `livedata` | MS-01 | `server` | Client app/VM host (openreturn + quorumcall); `enableSecrets=false` |
| `openreturn` | Small VM | `server` | OpenReturn app; standalone output *and* a `livedata` guest |
| `iso` | — | — | Custom installer with disko + agenix |

**microVM guests** (built by a parent host's `vms.nix`, not top-level outputs): `media` (Medium) + `torrent` (X-Small) on `homelab`; `openreturn` + `quorumcall` (Small) on `livedata`; `lanstation-vm` (Large, the gaming guest) on `lanstation` (WIP). `htpc` and `vault` (local Steam cache) are defined but not yet wired to a parent.

### Secrets / Security

- **agenix** manages secrets encrypted to Yubikey-backed SSH keys
- **GPG** and **Yubikey** modules handle hardware key integration
- The ISO boots with Yubikey SSH auth; installs using `INITIAL_INSTALL_MODE=1` for a minimal first pass, then does a full rebuild

### specialArgs Pattern

Global config (`settings.nix`) is available throughout the tree as `cala-m-os`:

```nix
# Access in any module
{ cala-m-os, ... }:
cala-m-os.globals.defaultUser  # "hub"
cala-m-os.globals.TZ           # "America/Denver"
cala-m-os.ip.lab.gateway       # "10.10.10.1"
```

### Adding a New Module

1. Scaffold from the template: `nix flake init -t .#module` (or create `modules/<name>/` by hand)
2. Provide **both** `modules/<name>/configuration.nix` and `modules/<name>/home.nix` (stub the unused one)
3. `git add` the new files before evaluating, then opt in by adding the bare `<name>` to the `modules` list of the relevant user profile(s) in `users/<username>/default.nix`

### Adding a New Host

1. Scaffold from the template: `nix flake init -t .#host` (or create `hosts/<hostname>/configuration.nix` by hand), specifying `users_list`, `machine_uuid`, `machine_type`. Import `../_core/default.nix` (the wrapper that adds the `initialInstallMode` installer branch), **not** `../_core/configuration.nix` directly.
2. Add to `flake.nix` under `nixosConfigurations` using `mkSystem`
3. Add machine hardware config under `machines/workstations/<UUID>/` if it's new hardware (resolved via `machines/resolve.nix`)
4. For a microVM **guest** instead of a top-level host, declare it in a parent host's `vms.nix` rather than adding a `mkSystem` output
