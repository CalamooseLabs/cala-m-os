# cala-help — the dev shell's cheat sheet. shell.nix prints `cala-help --banner`
# when you enter the repo (direnv, or an interactive `nix develop`);
# `cala-help [topic]` prints the longer version.
#
#   cala-help [--banner | rebuild | check | update | media | install | remote | dev]
{
  lib,
  writeShellApplication,
  coreutils,
  git,
  hosts,
}:
writeShellApplication {
  name = "cala-help";
  runtimeInputs = [coreutils git];
  text = ''
    HOSTS="${lib.concatStringsSep " " hosts}"
    TOPICS="rebuild check update media install remote dev"

    if [ -t 1 ] && [ -z "''${NO_COLOR:-}" ]; then
      B=$'\e[1m' D=$'\e[2m' C=$'\e[36m' Y=$'\e[33m' R=$'\e[0m'
    else
      B="" D="" C="" Y="" R=""
    fi

    me=$(cat /proc/sys/kernel/hostname 2>/dev/null) || me=unknown
    # `--flake .` picks the config named after this machine; elsewhere (the
    # installer, a microVM guest) name one.
    case " $HOSTS " in
      *" $me "*) this=$me flake="." here=" (.#$me)" ;;
      *) this="<host>" flake=".#<host>" here="" ;;
    esac

    branch="" ahead=0
    if root=$(git rev-parse --show-toplevel 2>/dev/null); then
      branch=$(git -C "$root" symbolic-ref --short -q HEAD) ||
        branch=$(git -C "$root" rev-parse --short HEAD 2>/dev/null) || branch=""
      ahead=$(git -C "$root" rev-list --count '@{u}..HEAD' 2>/dev/null) || ahead=0
    fi

    # Under direnv the shellHook runs before the system PATH is appended, so also
    # look where NixOS and home-manager put things.
    have() {
      command -v "$1" >/dev/null 2>&1 ||
        [ -x "/run/current-system/sw/bin/$1" ] ||
        [ -x "/etc/profiles/per-user/$(id -un)/bin/$1" ]
    }

    # emit LEAD WIDTH COMMAND [WHAT]: WHAT lines up in one column. A COMMAND too
    # long for it keeps WHAT on its line if that still fits in 100 columns, and
    # otherwise moves it under the column. Keep COMMAND plain ASCII: printf pads bytes.
    emit() {
      local lead=$1 width=$2 cmd=$3 what=''${4:-}
      if [ -z "$what" ]; then
        printf '%s%s%s%s\n' "$lead" "$C" "$cmd" "$R"
      elif [ "''${#cmd}" -le "$width" ]; then
        printf '%s%s%-*s%s  %s\n' "$lead" "$C" "$width" "$cmd" "$R" "$what"
      elif [ $((''${#lead} + ''${#cmd} + 2 + ''${#what})) -le 100 ]; then
        printf '%s%s%s%s  %s\n' "$lead" "$C" "$cmd" "$R" "$what"
      else
        printf '%s%s%s%s\n%*s  %s\n' "$lead" "$C" "$cmd" "$R" $((''${#lead} + width)) "" "$what"
      fi
    }
    row() { emit "$(printf '  %-8s ' "$1")" 38 "$2" "''${3:-}"; }
    cmd() { emit "  " 52 "$1" "''${2:-}"; }
    note() { printf '  %s%s%s\n' "$D" "$*" "$R"; }
    section() { printf '\n%s%s%s\n' "$B" "$*" "$R"; }
    push_warning() {
      [ "$ahead" -eq 0 ] ||
        printf '  %s! %s unpushed commit(s): installs and cala-reinstall build github master, not this checkout%s\n' "$Y" "$ahead" "$R"
    }

    banner() {
      printf '%sCala-M-OS%s  %s%s   %smore: cala-help [%s]%s\n' \
        "$B" "$R" "$me" "''${branch:+ · $branch}" "$D" "''${TOPICS// /|}" "$R"
      row rebuild "sudo nixos-rebuild switch --flake $flake" "''${here:+this host$here; }--show-trace to debug"
      local alt=()
      have nh && alt+=("nh os switch")
      have rebuild-config && alt+=("rebuild-config")
      if [ "''${#alt[@]}" -gt 0 ]; then
        local joined
        printf -v joined '%s, ' "''${alt[@]}"
        row "" "''${joined%, }" "the same, run as you"
      fi
      row check "nix build .#checks.x86_64-linux.$this --no-link" "evaluate without building"
      row format "alejandra ."
      row update "nix flake update <input>" "always by name; nixpkgs-beta moves only beta"
      row usb "flash-iso [--with-pat]" "build the installer, dd it to a stick (+ Proton PAT)"
      row iso "build-pat-iso --vault <vault>" "installer .iso file with the PAT inside, no stick"
      row kexec "sudo cala-reinstall" "on a host: reboot into the installer in RAM"
      row deploy "nixos-rebuild switch --flake .#<host> --target-host hub@<ip> --sudo"
      row cloud "nix run github:nix-community/nixos-anywhere -- --flake .#<host> --target-host root@<ip>" "first install from Hetzner Rescue"
      row edit "zeditor ." "Zed wired to nixd/nil + alejandra"
      local lead="  hosts    " line
      while IFS= read -r line; do
        printf '%s%s\n' "$lead" "''${line% }"
        lead="           "
      done < <(fold -s -w 78 <<<"$HOSTS")
      push_warning
    }

    topic_rebuild() {
      section "rebuild: apply a config"
      cmd "sudo nixos-rebuild switch --flake $flake" "build + activate$here"
      cmd "sudo nixos-rebuild boot --flake $flake" "activate on the next boot"
      cmd "sudo nixos-rebuild test --flake $flake" "activate now, no boot entry"
      cmd "nixos-rebuild build --flake $flake" "build only, into ./result (no sudo)"
      cmd "sudo nixos-rebuild switch --rollback" "back to the previous generation"
      have nh && cmd "nh os switch [--ask]" "the same, run as you; --ask shows the diff first"
      have rebuild-config && cmd "rebuild-config" "lazygit if the tree is dirty, then nh os switch"
      note "--show-trace shows where an eval error comes from"
      note "microVM guests rebuild with their parent: .#homelab (media torrent security), .#livedata (openreturn quorumcall)"
      note "hosts: $HOSTS"
    }

    topic_check() {
      section "check: evaluate + format"
      cmd "alejandra ." "format every .nix file (or nix fmt . -- the dot matters)"
      cmd "nix build .#checks.x86_64-linux.$this --no-link" "evaluate one host without building it"
      cmd "nix flake check --keep-going" "evaluate every host"
      cmd "nix eval .#nixosConfigurations.$this.config.<option>" "print one option (--raw for strings)"
      cmd "nix repl ." "explore the flake interactively"
      note "the flake only sees files git knows about: git add new files before evaluating"
    }

    topic_update() {
      section "update: flake inputs"
      cmd "nix flake update <input> [<input>...]" "always by name"
      cmd "nix flake update nixpkgs-beta" "move only the beta pin"
      cmd "nix flake update nixpkgs" "graduate beta, then clear the calamoose.beta / modules.<name>.beta lists"
      cmd "sudo nix flake update bookkeeper cobblemon-initiative" "private inputs: only root can read the GitHub token"
      cmd "nix flake metadata" "inputs and their locked revs"
      note "a bare 'nix flake update' moves nixpkgs AND nixpkgs-beta to the same rev, so beta stops riding ahead"
    }

    topic_media() {
      section "media: installer ISO, USB stick, or no media at all"
      cmd "nix build" "installer ISO -> result/iso/*.iso"
      cmd "flash-iso" "build it, pick a USB stick, dd it (type YES, then sudo)"
      cmd "flash-iso --with-pat | --pat-file <file>" "...plus a CALAPAT partition holding a Proton PAT"
      cmd "build-pat-iso --vault <vault>" "an ISO FILE with the PAT inside, no stick (cloud custom-ISO slot, VM)"
      note "  writes ~/cala-m-os-installer-pat.iso; also --pat-file <f>  --out <f>  --force  --no-check  --item/--field"
      note "  --shared-vault reads the Cala-M-OS vault instead of --vault: the PAT then exposes whatever it is granted there"
      note "  anyone holding the ISO can use the PAT: grant it one vault only, revoke it after the install"
      cmd "qemu-system-x86_64 -enable-kvm -m 4G -cdrom <file.iso>" "test-boot an ISO in a VM"
      cmd "nix build .#installer-kexec" "the same installer as a RAM-only kexec image"
      cmd "sudo cala-reinstall --dry-run" "on the host: load that image, then unload it"
      cmd "sudo cala-reinstall [--token-file <f> | --pat-file <f>]" "on the host: jump into the installer (every physical host)"
      note "  --variant full|vm picks the image (vm = no firmware, fits 4 GB cloud boxes; auto-detected)"
      note "the installer and cala-reinstall build github:CalamooseLabs/cala-m-os master: push first"
      push_warning
    }

    topic_install() {
      section "install: inside the booted installer"
      cmd "cala-installer" "the TUI (starts by itself on tty1)"
      cmd "sudo install-cala-m-os <host> [<machine>]" "unattended only for battlestation, broadcast, homelab (wipeAllDisks)"
      cmd "sudo disko --mode destroy,format,mount --flake github:CalamooseLabs/cala-m-os#<host>"
      cmd "sudo INSTALL_SKIP_DISKO=1 install-cala-m-os <host>" "every other host (cloud VMs included): disko by hand, then this; the TUI does both"
      cmd "sudo INSTALL_OS_DISK=/dev/disk/by-id/<id> install-cala-m-os homelab" "onto a replacement OS disk"
      cmd "ssh root@<installer-ip>" "YubiKey sk keys; no mDNS, so take the IP from ip -br addr"
      cmd "journalctl -u cala-nix-token" "did the media's PAT get the GitHub token? retry: sudo cala-nix-token --force"
      note "env vars go after sudo: sudo drops anything set before it"
    }

    topic_remote() {
      section "remote: deploy from here, microVM guests"
      cmd "nixos-rebuild switch --flake .#<host> --target-host hub@<ip> --sudo" "build here, activate there"
      note "add --build-host hub@<ip> to build on the target instead (webhost: aarch64, plus --no-reexec)"
      cmd "nix run github:nix-community/nixos-anywhere -- --flake .#<host> --target-host root@<ip>" "first install of a cloud box from Hetzner Rescue"
      note "tci-cloud has a private input: run both as root (sudo --preserve-env=SSH_AUTH_SOCK); webhost adds --build-on remote"
      cmd "microvm -l" "on a VM host: guests and whether they are current"
      cmd "sudo systemctl restart microvm@<guest>" "restart one; journalctl -u microvm@<guest> -f for its console"
      cmd "ssh hub@<guest-ip>" "a shell in a guest"
      note "guests: media torrent security on homelab · openreturn quorumcall on livedata"
    }

    topic_dev() {
      section "dev: scaffolding, secrets, housekeeping"
      cmd "nix flake init -t .#module" "inside a new modules/<name>/ (also #host #user #secret)"
      note "a module needs configuration.nix AND home.nix; enroll it in users/<profile>/default.nix"
      cmd "agenix -e <name>.age -i /etc/nixos/modules/agenix/identities/yubi.key" "edit a secret, from the bundle's secrets/ dir, YubiKey in"
      cmd "sudo systemctl restart agenix-rerun" "decrypt again after plugging in the YubiKey"
      if have nh; then
        cmd "nh clean all --keep 3" "garbage-collect"
      else
        cmd "sudo nix-collect-garbage --delete-older-than 3d" "garbage-collect"
      fi
      cmd "zeditor ." "Zed wired to nixd/nil + alejandra"
      cmd "direnv reload" "pick up shell.nix edits (direnv only watches flake.nix + flake.lock)"
    }

    case "''${1:-all}" in
      --banner) banner ;;
      all) for t in $TOPICS; do "topic_$t"; done ;;
      -h | --help) echo "usage: cala-help [--banner | ''${TOPICS// / | }]" ;;
      *)
        case " $TOPICS " in
          *" $1 "*) "topic_$1" ;;
          *)
            echo "cala-help: no topic '$1' (topics: $TOPICS)" >&2
            exit 64
            ;;
        esac
        ;;
    esac
  '';
}
