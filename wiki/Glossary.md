# Glossary

Project-specific terms and where to read more.

| Term | Meaning |
|------|---------|
| **Cala-M-OS** | This repo: one NixOS flake building the whole Calamoose Labs fleet |
| **`cala-m-os`** | The settings attrset (`settings.nix`) injected everywhere via `specialArgs`. See [[Global Settings|Global-Settings]] |
| **host** | A configurable machine: `hosts/<name>/`. Declares users + machine identity; hardware-agnostic. See [[Hosts|Hosts]] |
| **`_core`** | The shared layer every host expands into (`hosts/_core/`). See [[Configuration Hierarchy|Configuration-Hierarchy]] |
| **machine** | The hardware layer: `machines/workstations/<UUID>/` or `machines/vms/<size>/`. See [[Machines|Machines]] |
| **`machine_uuid`** | The hardware directory name a host selects (e.g. `FW16-AMD-AI`, `Small`) |
| **`machine_type`** | `"Workstation"` or `"VM"` — selects hardware source + whether `non-vm.nix` applies |
| **hardware module** | `machines/modules/<gpu\|cpu>` — driver enablement imported by workstation configs |
| **module** | A program + its settings: `modules/<name>/{configuration,home}.nix`. See [[Modules|Modules]] |
| **two-file convention** | Every module ships both a system (`configuration.nix`) and home (`home.nix`) file, even if one is an empty stub |
| **service** | Heavier infrastructure as an idiomatic NixOS module under `services.cala-*`. See [[Services|Services]] |
| **profile** | A user definition: `users/<profile>/`. Lists modules by name. See [[Users & Profiles|Users-and-Profiles]] |
| **`hub`** | The canonical primary username; the default profile maps to it; the persona switcher account |
| **persona / switching** | `hub` adopting another user's environment live via `change-user`/`swap-user`/`exit-user`. See [[User Switching|User-Switching]] |
| **`userSwitching`** | The option enabling persona switching (auto-on when `users_list` ≥ 2) |
| **`personas` group** | Shared Unix group + `homeMode=770` that lets hub and personas read each other's homes |
| **`mkSystem`** | The `flake.nix` helper that builds a host. See [[Flake & Inputs|Flake-and-Inputs]] |
| **`specialArgs`** | Module arguments injected at the flake level: `inputs`, `cala-m-os`, `initialInstallMode` |
| **`initialInstallMode`** | Boolean from `INITIAL_INSTALL_MODE` env var; selects the minimal first-pass install config. See [[ISO & Installer|ISO-Installer]] |
| **`calamoose.enableSecrets`** | Per-host option gating all agenix secret loading (default `true`) |
| **agenix** | Age-based secret manager; secrets encrypted to Yubikey recipients. See [[Secrets & Security|Secrets-and-Security]] |
| **`/run/agenix`** | Where decrypted secrets land on a host |
| **`/run/hostsecrets`** | Where a MicroVM guest sees the host's `/run/agenix` (read-only virtiofs) |
| **MicroVM** | The only VM type used (microvm.nix/QEMU). See [[MicroVMs|MicroVMs]] |
| **`cala-vm-manager`** | The service that turns a declarative `vms` set into MicroVM guests |
| **`hostOverride`** | A guest field: build the VM from a different host config than its name |
| **macvtap** | The bridged interface type guests use to appear on the LAN |
| **disko** | Declarative disk partitioning; layout lives in each machine's `disko.nix` |
| **stylix** | System-wide theming module |
| **`flash-iso`** | Dev-shell helper: build the ISO and `dd` it to a USB stick |
| **`non-vm.nix`** | Workstation-only settings (unfree, store auto-optimise, `/etc/nixos` perms, NetworkManager) |
