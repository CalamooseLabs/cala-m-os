{
  lib,
  config,
  pkgs,
  ...
}: let
  # First-boot runner for calamoose.install.firstBootCommands. Each entry becomes
  # a one-shot unit that runs ONCE per fresh root filesystem: a stamp under
  # fbStampDir gates it, and that stamp lives on the root that a teardown wipes.
  # So an ordinary `nixos-rebuild switch` finds the stamp and skips, but a
  # teardown + full install (or a recreated microVM .img) starts with an empty
  # root, no stamp, and re-runs. Built for the media-stack restores, which must
  # run INSIDE a guest on its first boot — by then the host has shared decrypted
  # secrets into /run/hostsecrets and the NAS backup shares are mounted, neither
  # of which is true at host-installer time (and the guest doesn't exist yet).
  fbc = config.calamoose.install.firstBootCommands;
  fbStampDir = "/var/lib/cala-firstboot";
  mkFirstBootUnit = name: c: let
    stamp = "${fbStampDir}/${name}.done";
    runner = pkgs.writeShellScript "cala-firstboot-${name}" ''
      set -uo pipefail
      rc=0
      ${c.run} || rc="''$?"
      # Stamp on success only (default) so a first boot where the backup was not
      # yet reachable is retried next boot; stampOnFailure=true marks it done
      # regardless. `true`/`false` below are shell builtins.
      if [ "''$rc" -eq 0 ] || ${lib.boolToString c.stampOnFailure}; then
        install -d -m 0755 ${fbStampDir}
        touch ${stamp}
      fi
      exit "''$rc"
    '';
  in {
    description = "First-boot task '${name}' (runs once per fresh install)";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"] ++ c.after;
    before = c.before;
    unitConfig =
      {
        ConditionPathExists = "!${stamp}";
      }
      // lib.optionalAttrs (c.requiresMounts != []) {
        RequiresMountsFor = c.requiresMounts;
      };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = c.user;
      ExecStart = runner;
    };
    # Resolve `run` (e.g. plex-restore, from environment.systemPackages) and the
    # coreutils used above against the full system profile.
    path = [config.system.path];
  };
in {
  options.calamoose.enableSecrets = lib.mkOption {
    # Tri-state, backward-compatible:
    #   false            -> no secrets loaded
    #   true | "offline" -> agenix        (decrypt to /run/agenix)        [default]
    #   "online"         -> Proton Pass   (decrypt to /run/proton-secrets)
    # The bool form is retained so existing `= false` / `= true` hosts still parse.
    type = lib.types.either lib.types.bool (lib.types.enum ["offline" "online"]);
    default = "offline";
    example = "online";
    description = ''
      Secrets backend for this host. `false` disables secrets; `true`/"offline"
      uses agenix (Yubikey/age, offline); "online" uses the Proton Pass CLI
      (services.proton-secrets) to fetch secrets at activation.
    '';
  };

  # Resolved, read-only backend — the single source of truth for every consumer.
  options.calamoose._secretsBackend = lib.mkOption {
    type = lib.types.enum ["none" "agenix" "proton-pass"];
    readOnly = true;
    internal = true;
    description = "Resolved secrets backend, computed from enableSecrets. Do not set.";
  };

  # Convenience bool for `mkIf` gates (enableSecrets may be a string, which mkIf rejects).
  options.calamoose._secretsEnabled = lib.mkOption {
    type = lib.types.bool;
    readOnly = true;
    internal = true;
    description = "True when any secrets backend is active. Use in mkIf. Do not set.";
  };

  options.calamoose.style = lib.mkOption {
    type = lib.types.enum ["calamooselabs" "blank" "thecompany"];
    default = "calamooselabs";
    example = "thecompany";
    description = ''
      Visual style (Stylix theme) for this host — selects the system-wide base16
      palette, fonts, wallpaper, cursor, and Plymouth logo. Consumed by
      modules/stylix/configuration.nix.

        "calamooselabs" (default) — the house gruvbox-ish dark palette + photo wallpaper.
        "blank"                   — minimal grayscale dark; no accent color, solid background.
        "thecompany"              — The Company, Inc. brand theme, per its Brand Guidelines:
                                    Incognito Black base with the electric Blue Screen of Death
                                    / Circle-Back Cyan accents, Outfit + BioRhyme Expanded fonts, and the
                                    "Evil Eye" logomark wallpaper + boot logo.
    '';
  };

  options.calamoose.version = lib.mkOption {
    type = lib.types.str;
    default = "0.0.1-beta";
    description = ''
      Human-set version mark for this host. The installer prints it at the start
      and end of an install, and it is appended to the system label so it shows in
      `nixos-version` and the systemd-boot menu entry.
    '';
  };

  options.calamoose.install.wipeAllDisks = lib.mkOption {
    type = lib.types.bool;
    default = false;
    example = true;
    description = ''
      Install-time disk policy read by `install-cala-m-os`. When true, disko runs
      in destroy,format,mount mode with --yes-wipe-all-disks — an unattended full
      wipe of EVERY disk in this host's disko config. Leave false (default) for
      machines that dual-boot or own only some disks: the installer then refuses
      to auto-partition rather than blowing them away. Set true only for boxes
      NixOS fully owns (e.g. broadcast/TRX50-SAGE).
    '';
  };

  options.calamoose.install.dataDisks = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        device = lib.mkOption {
          type = lib.types.str;
          example = "/dev/disk/by-id/nvme-WDS200T1X0E-00AFY0_22042X800647";
          description = ''
            Stable /dev/disk/by-id path of the data disk. NEVER use /dev/nvmeXn1
            or /dev/sdX — kernel enumeration order is not stable, especially
            between the installed system and the installer ISO.
          '';
        };
        label = lib.mkOption {
          type = lib.types.str;
          example = "battle-data";
          description = ''
            Filesystem label. Used by the installer's mkfs AND by the by-label
            `fileSystems` mount you declare for this disk.
          '';
        };
        fsType = lib.mkOption {
          type = lib.types.enum ["ext4" "xfs"];
          default = "ext4";
          description = "Filesystem the installer creates when you choose to (re)format this disk.";
        };
      };
    });
    default = [];
    example = lib.literalExpression ''
      [
        {
          device = "/dev/disk/by-id/nvme-WDS200T1X0E-00AFY0_22042X800647";
          label = "battle-data";
          fsType = "xfs";
        }
      ]
    '';
    description = ''
      Preserved data disks handled by `install-cala-m-os` AFTER the main install,
      one interactive prompt each. These are deliberately NOT part of disko, so a
      reinstall NEVER wipes them: the installer defaults to KEEP and only
      reformats on an explicit `W` from a terminal (a non-interactive run always
      keeps them). Mount each one yourself via `fileSystems` keyed on
      `/dev/disk/by-label/<label>` with the `nofail` option so an absent or
      not-yet-formatted disk can't block boot. Distinct from `wipeAllDisks`,
      which governs the disko-owned OS disk(s).
    '';
  };

  options.calamoose.install.firstBootCommands = lib.mkOption {
    default = {};
    description = ''
      Commands to run ONCE on the first boot after a fresh install — a teardown +
      full install, or a recreated microVM root image — and NOT on an ordinary
      `nixos-rebuild switch`. Keyed by a short, stable name used for the unit and
      its run-once stamp (${fbStampDir}/<name>.done); the stamp lives on the root
      a wipe destroys, which is what tells a fresh install apart from a rebuild.

      Primarily for the media-stack restores that must run inside a guest on its
      first boot (host secrets are already at /run/hostsecrets and the NAS backup
      shares are mounted by then), where the host installer cannot reach guest
      state. A missing backup just means the restore exits non-zero and is retried
      next boot (see stampOnFailure).
    '';
    example = lib.literalExpression ''
      {
        plex-restore = {
          run = "plex-restore";
          requiresMounts = ["/mnt/backup"];
          after = ["plex.service"];
        };
      }
    '';
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        run = lib.mkOption {
          type = lib.types.str;
          example = "plex-restore";
          description = "Command line run once on first boot. Resolved against the system PATH.";
        };
        requiresMounts = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          example = ["/mnt/backup"];
          description = "Mount points the unit waits for (RequiresMountsFor) — e.g. the NAS backup share the restore reads.";
        };
        after = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          example = ["plex.service"];
          description = ''
            Extra After= ordering (network-online.target is always added). A
            restore whose script stops/starts its own service must be ordered
            AFTER that service (e.g. "plex.service"), never Before — a Before= on
            a service the command itself starts is an ordering cycle.
          '';
        };
        before = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Before= ordering, for commands that must precede another unit.";
        };
        user = lib.mkOption {
          type = lib.types.str;
          default = "root";
          description = "User to run as. Restores that stop/start services and chown files need root.";
        };
        stampOnFailure = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Write the run-once stamp even when the command fails. Default false:
            the stamp is written only on success, so a first boot where the backup
            was not yet reachable (non-zero exit) is retried on the next boot
            rather than being marked done.
          '';
        };
      };
    });
  };

  options.calamoose.hardlinkLayout = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Media import layout for hosts running qBittorrent + the *arr suite.

      false (default): qBittorrent downloads to local disk and the library is
      NFS-mounted per folder, so an *arr import copies the file across
      filesystems into the NAS.

      true: a single NFS mount of the library root (nfs.media.root) holds both
      downloads and the library, so *arr imports become instant hardlinks (no
      data copied). Requires the NAS to export the library root with a
      Downloads/ dir writable by the qbittorrent uid, and the *arr root folders
      / remote-path mappings reconfigured to the shared mount.
    '';
  };

  # Surface the host version in `nixos-version` / the boot menu entry.
  config.system.nixos.tags = ["cala-${config.calamoose.version}"];

  # Emit one run-once unit per firstBootCommands entry (empty attrset -> no units).
  config.systemd.services =
    lib.mapAttrs'
    (name: c: lib.nameValuePair "cala-firstboot-${name}" (mkFirstBootUnit name c))
    fbc;

  # Disk-wipe safety net. The whole "disko can never touch the data drive" story
  # rests on two invariants; enforce them at eval time so a future foot-gun edit
  # (reverting the by-id pin to /dev/nvmeXn1, or pointing a dataDisk at a disko
  # disk) fails the build instead of silently wiping the wrong disk on install.
  config.assertions = let
    inst = config.calamoose.install;
    diskoDevices = lib.mapAttrsToList (_: d: d.device) (config.disko.devices.disk or {});
    byId = lib.hasPrefix "/dev/disk/by-id/";
    dataDevices = map (d: d.device) inst.dataDisks;
    unpinned = lib.filter (d: !byId d) diskoDevices;
    overlap = lib.filter (d: lib.elem d diskoDevices) dataDevices;
  in [
    {
      assertion = !inst.wipeAllDisks || unpinned == [];
      message = "calamoose.install.wipeAllDisks = true requires every disko disk to be pinned by a stable /dev/disk/by-id/ path (unstable target(s): ${lib.concatStringsSep ", " unpinned}). Under --yes-wipe-all-disks an enumeration-order name like /dev/nvme0n1 can wipe the wrong disk.";
    }
    {
      assertion = overlap == [];
      message = "calamoose.install.dataDisks must not list a disko-owned disk (overlap: ${lib.concatStringsSep ", " overlap}). A data disk is meant to be preserved and must never be a disko target, or wipeAllDisks would erase it.";
    }
  ];

  # Normalize the tri-state flag into the resolved backend + convenience bool.
  config.calamoose._secretsBackend = let
    v = config.calamoose.enableSecrets;
  in
    if v == false
    then "none"
    else if (v == true || v == "offline")
    then "agenix"
    else "proton-pass"; # v == "online"

  config.calamoose._secretsEnabled = config.calamoose._secretsBackend != "none";
}
