# Flake & Inputs

`flake.nix` is the single entry point. It pins inputs, defines the `mkSystem` helper, declares every machine, and exposes the dev shell, formatter, ISO package, and templates.

---

## Inputs

| Input | Source | Purpose |
|-------|--------|---------|
| `nixpkgs` | `github:nixos/nixpkgs/nixos-unstable` | Base package set (unstable channel) |
| `nixos-hardware` | `github:NixOS/nixos-hardware/master` | Hardware quirk fixes (e.g. Framework laptops) |
| `flatpaks` | `github:in-a-dil-emma/declarative-flatpak/latest` | Declarative Flatpak management |
| `preservation` | `github:nix-community/preservation` | Impermanence-style state/file preservation |
| `stylix` | `github:danth/stylix` | System-wide theming |
| `microvm` | `github:microvm-nix/microvm.nix` | MicroVM / QEMU guest framework |
| `hyprland` | `github:hyprwm/Hyprland` | Hyprland Wayland compositor |
| `hyprland-plugins` | `github:hyprwm/hyprland-plugins` | Hyprland plugins (pins its `hyprland` input) |
| `disko` | `github:nix-community/disko` | Declarative disk partitioning/formatting |
| `home-manager` | `github:nix-community/home-manager` | Per-user home configuration |
| `agenix` | `github:ryantm/agenix` | Age-based secret management (Yubikey-backed) |
| `arion` | `github:hercules-ci/arion` | Docker-Compose-style declarative containers |
| `antlers` | `github:CalamooseLabs/antlers` | In-house flake (repo root, default branch): the Nix-enabled `zed-editor` and `flash-iso` for the dev shell, the antlers NixOS/home-manager modules, and the `flakes/<name>/package.nix` files the installer image builds (`install-cala-m-os`, `cala-installer`, `proton-secrets`) relative to it |
| `openreturn` | `github:CalamooseLabs/OpenReturn` | In-house app/service (consumed by the `openreturn` module) |
| `quorumcall` | `github:CalamooseLabs/QuorumCall` | In-house app/service (consumed by the `quorumcall` module) |

Most inputs `follows = nixpkgs` to avoid duplicate nixpkgs evaluations. `antlers` is pinned at the repository root: `iso/installer.nix` and `iso/calapat.nix` read `inputs.antlers + "/flakes/scripts/package.nix"` (and `…/flakes/proton-secrets/package.nix`), which only resolves because the input is the whole repo.

---

## `mkSystem`

Every host is produced by this helper; the `iso` and the four `installer-kexec*` images are plain `nixpkgs.lib.nixosSystem` calls (see Outputs):

```nix
mkSystem = hostname: extraSpecialArgs:
  nixpkgs.lib.nixosSystem {
    inherit system;                                   # "x86_64-linux"
    specialArgs =
      { inherit inputs cala-m-os initialInstallMode; }
      // extraSpecialArgs;
    modules = [
      ./hosts/${hostname}/configuration.nix
      { nixpkgs.overlays = import ./overlays; }
    ];
  };
```

| Concern | Behavior |
|--------|----------|
| `hostname` | Selects `./hosts/<hostname>/configuration.nix` as the only top-level module |
| `extraSpecialArgs` | Merged over the base args; used to pass `self` to the two hosts that need it (`lanstation`, `homelab`) |
| `specialArgs` | Always provides `inputs`, `cala-m-os` (= `settings.nix`), and `initialInstallMode` |
| `system` | Hard-coded `x86_64-linux` (no `flake-utils`) |
| overlays | Applied via an inline module (`nixpkgs.overlays = import ./overlays`) |

Everything else (home-manager, disko, stylix, the machine/user/module tree) is pulled in **deeper**, by the host → `_core` chain — not at this top level. See [[Configuration Hierarchy|Configuration-Hierarchy]].

---

## Outputs

```mermaid
flowchart LR
  flake["flake.nix outputs"]
  flake --> nc["nixosConfigurations<br/>13 hosts + iso + installer-kexec{,-vm}{,-aarch64}"]
  flake --> chk["checks.x86_64-linux → one eval check per nixosConfiguration"]
  flake --> fmt["formatter → alejandra"]
  flake --> pkg["packages.default → installer ISO image"]
  flake --> tpl["templates → host / module / user / secret"]
  flake --> dev["devShells.default → shell.nix"]
```

- **`nixosConfigurations`** — `lanstation`, `devbox`, `ephemeral`, `homelab`, `simple`, `battlestation`, `broadcast`, `openreturn`, `livedata`, `ai`, `tci-cloud`, `tci-private`, `webhost` (aarch64), plus `iso`. `installer-kexec` is the same installer as a RAM-only kexec image (`iso/kexec.nix`), used by `cala-reinstall`; `installer-kexec-vm` drops linux-firmware (`iso/kexec-vm.nix`) for VMs, and `installer-kexec-aarch64` / `installer-kexec-vm-aarch64` are the same two for aarch64 hosts. The `iso` and the kexec images are built directly (not via `mkSystem`) and get only `inputs` in `specialArgs`. See [[Hosts|Hosts]].
- **`formatter`** → `alejandra` (so `nix fmt` ≡ `alejandra .`).
- **`packages.x86_64-linux.default`** → `nixosConfigurations.iso.config.system.build.isoImage`, so `nix build` builds the ISO.
- **`packages.<system>.installer-kexec`** / **`installer-kexec-vm`** (for `x86_64-linux` and `aarch64-linux`) → the kexec image (`bzImage`, `initrd`, `cmdline`) that `cala-reinstall` boots; `<flake>#installer-kexec` resolves to the running host's own architecture. See [[ISO & Installer|ISO-Installer]].
- **`packages.<system>.installer-tools`** (for `x86_64-linux` and `aarch64-linux`) → the live installer's own tools (`iso/tools.nix`: `cala-installer`, the token-aware `install-cala-m-os` shim + backend, `cala-nix-token`) as one package; what the TUI's "Update the installer" pulls from the flake. See [[ISO & Installer|ISO-Installer]].
- **`templates`** → imported from `./templates` (see below).
- **`devShells.${system}.default`** → `./shell.nix`.

- **`checks.x86_64-linux.<name>`** — one check per `nixosConfigurations` entry (the aarch64 ones included) that forces its `toplevel.drvPath` and echoes it, so `nix flake check` evaluates every host's module tree (options, assertions, infinite recursion) without building anything.

There is **no `apps`** output.

---

## Overlays

`overlays/default.nix` is currently the empty list:

```nix
[]
```

It's a wired-in extension point (imported by both the dev-shell `pkgs` and the `mkSystem` inline module) but presently overrides/adds nothing.

---

## Dev shell — `shell.nix`

`nix develop` provides:

| Tool | Purpose |
|------|---------|
| `alejandra` | The canonical Nix formatter |
| `nixd`, `nil` | Nix language servers |
| `claude-code` | Claude Code CLI |
| `flash-iso` | Interactive ISO build-and-flash helper (below) |
| `build-pat-iso` | Build the ISO as a file with a Proton PAT inside, for cloud custom-ISO uploads (see [[ISO & Installer|ISO-Installer]]) |
| `zed-editor` (from `antlers`) | Nix-enabled Zed, pre-wired to use `nil`/`nixd` + `alejandra` formatting |

The shell hook prints `Using Local Nix-Enabled Zed!`.

### `flash-iso`

A `writeShellApplication` that builds the ISO and writes it to a USB stick, interactively:

1. Resolve flake root (`git rev-parse --show-toplevel`).
2. List USB block devices (`lsblk -J | jq 'select(.tran=="usb")'`); abort if none.
3. Prompt for a target drive.
4. Show a destructive-data warning; require typing `YES`.
5. `nix build .#nixosConfigurations.iso.config.system.build.isoImage`.
6. Unmount any mounted partitions on the target.
7. `sudo dd if=<iso> of=<device> bs=4M status=progress oflag=sync`.

Run it with `nix develop -c flash-iso`.

---

## Templates

`templates/default.nix` exposes four scaffolds (no `default` alias — you must name one):

| Template | Creates | Notes |
|----------|---------|-------|
| `host` | a host flake skeleton | |
| `module` | a module skeleton | |
| `user` | a user profile skeleton | |
| `secret` | an agenix secret bundle | `welcomeText` reminds: `agenix -e <file>.age -i ./identities/yubi.key` |

```bash
nix flake init -t /etc/nixos#module
```

See [[Common Tasks|Common-Tasks]] for end-to-end recipes.

---

## `initialInstallMode` threading

`flake.nix` reads an env var at evaluation time (impure):

```nix
initialInstallMode = builtins.getEnv "INITIAL_INSTALL_MODE" == "1";
```

This boolean is injected into every host's `specialArgs` and is the switch that selects the minimal first-pass config during installation. It requires `--impure` when evaluated, which is why the installer passes it. Full detail in [[ISO & Installer|ISO-Installer]] and [[Configuration Hierarchy|Configuration-Hierarchy]].
