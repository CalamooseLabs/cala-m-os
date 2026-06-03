# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

**Cala-M-OS** is a multi-host NixOS flake configuration managing workstations, servers, VMs, and a custom installer ISO. The flake supports 6 hosts: `lanstation`, `devbox`, `ephemeral`, `lab`, `simple`, `studio`, and `iso`.

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
flake.nix  (mkSystem function → 6 host outputs)
  └── hosts/<hostname>/configuration.nix  (host-specific params: users_list, machine_uuid, machine_type)
        └── hosts/_core/default.nix  (parameterized common config — imports core + machine + users)
              ├── hosts/_core/configuration.nix  (boot, networking, GC, greetd, firewall, timezone)
              ├── hosts/_core/home.nix  (home-manager entry point)
              ├── machines/workstations/<UUID>/configuration.nix  (hardware-specific)
              └── users/<username>/default.nix  (user profile → imports modules)
```

### Module System

Modules live in `modules/<name>/` with two optional files:
- `configuration.nix` — NixOS system-level config
- `home.nix` — Home-manager user config

Users import their needed modules in `users/<username>/default.nix`. The `debugger` user (used by devbox) is the most comprehensive with 65+ modules.

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

| Host | Machine | Primary User | Notes |
|------|---------|-------------|-------|
| `lanstation` | TRX50-SAGE | `gamer` | GPU passthrough/VFIO, static IP, VM host |
| `devbox` | FW16-AMD-AI | `debugger` | Framework 16, NVIDIA 5070, printing |
| `iso` | — | — | Custom installer with disko + agenix |

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
cala-m-os.ip.gateway           # "10.10.10.1"
```

### Adding a New Module

1. Create `modules/<name>/configuration.nix` and/or `modules/<name>/home.nix`
2. Add the module import to the relevant user profile(s) in `users/<username>/default.nix`

### Adding a New Host

1. Create `hosts/<hostname>/configuration.nix` specifying `users_list`, `machine_uuid`, `machine_type`
2. Add to `flake.nix` under `nixosConfigurations` using `mkSystem`
3. Add machine hardware config under `machines/workstations/<UUID>/` if new hardware
