# OBS runtime config: declarative *baseline* that the machine may override.
#
# OBS constantly rewrites its own config (global.ini, scene JSON, profile
# basic.ini), so a read-only Nix-store symlink (home.file/xdg.configFile) would
# break it and forbid quick on-box edits. Instead we SEED: on first activation
# we copy the committed baseline into ~/.config/obs-studio only where a file is
# absent, then never touch it again — the machine owns it and live edits survive
# every rebuild. Two escape hatches make it a round-trip:
#   obs-config-restore   force the committed baseline back over the live config
#                        (after backing the live config up)
#   obs-config-snapshot  mirror the live profiles/scenes back into the repo
#                        working tree so you can `git add` + commit them
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.calamoose.obs;
  obsDir = "${config.xdg.configHome}/obs-studio";

  # Force the committed baseline back over the live config (after backing it up).
  restoreApp = pkgs.writeShellApplication {
    name = "obs-config-restore";
    runtimeInputs = [pkgs.coreutils pkgs.gnutar];
    text = ''
      src="${toString cfg.seedSource}"
      obsDir="${obsDir}"

      if [ "''${1:-}" != "--yes" ]; then
        printf 'This overwrites the committed OBS baseline (profiles/scenes/global.ini)\n'
        printf 'over your live config at %s\n' "$obsDir"
        printf 'A backup is taken first. Continue? [y/N] '
        read -r reply
        case "$reply" in
          [yY]*) ;;
          *) echo "aborted"; exit 1 ;;
        esac
      fi

      if [ -d "$obsDir" ]; then
        ts="$(date +%Y%m%d-%H%M%S)"
        backup="$obsDir.backup-$ts.tar.gz"
        tar czf "$backup" -C "$(dirname "$obsDir")" "$(basename "$obsDir")"
        echo "backed up live config to $backup"
      fi

      mkdir -p "$obsDir"
      for item in basic global.ini; do
        [ -e "$src/$item" ] || continue
        if [ -d "$src/$item" ]; then
          mkdir -p "$obsDir/$item"
          cp -rf --no-preserve=mode "$src/$item/." "$obsDir/$item/"
        else
          cp -f --no-preserve=mode "$src/$item" "$obsDir/$item"
        fi
      done
      echo "restored baseline into $obsDir (restart OBS to load it)"
    '';
  };

  # Mirror the live profiles/scenes back into the repo working tree for committing.
  # Keyed off repoPath, NOT seedSource: this is how the FIRST baseline is captured
  # from a running box, so it must be available before any baseline exists.
  snapshotApp = pkgs.writeShellApplication {
    name = "obs-config-snapshot";
    runtimeInputs = [pkgs.coreutils pkgs.rsync];
    text = ''
      repo="${toString cfg.repoPath}"
      obsDir="${obsDir}"

      withGlobal=0
      [ "''${1:-}" = "--with-global" ] && withGlobal=1

      if [ ! -d "$obsDir/basic" ]; then
        echo "no OBS config found at $obsDir/basic — nothing to snapshot" >&2
        exit 1
      fi

      mkdir -p "$repo/basic/profiles" "$repo/basic/scenes"
      # Mirror the meaningful content; --delete keeps the repo in sync with
      # profiles/collections you removed on the box.
      rsync -rlt --delete --no-owner --no-group "$obsDir/basic/profiles/" "$repo/basic/profiles/"
      rsync -rlt --delete --no-owner --no-group "$obsDir/basic/scenes/"   "$repo/basic/scenes/"

      # global.ini carries the "current profile/collection" pointer that lets
      # a fresh box open straight into the right setup, but also machine-local
      # noise (window geometry, hotkeys). Opt in with --with-global.
      if [ "$withGlobal" = 1 ] && [ -e "$obsDir/global.ini" ]; then
        cp -f --no-preserve=mode "$obsDir/global.ini" "$repo/global.ini"
        echo "snapshotted global.ini (review it before committing)"
      fi

      echo "snapshotted profiles + scenes into $repo"
      echo "review with: git -C \"$repo\" status && git -C \"$repo\" diff"
    '';
  };
in {
  options.calamoose.obs = {
    seedSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Store path of the committed OBS baseline (a directory that may contain
        `basic/` and `global.ini`). When set, its contents are copied into
        {file}`~/.config/obs-studio` on activation, but only where the target
        file does not already exist. Null disables all seeding for this user.
      '';
    };

    repoPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/etc/nixos/machines/workstations/TRX50-SAGE/obs";
      description = ''
        Absolute working-tree path of the baseline directory. Used only by
        `obs-config-snapshot` to write the live machine config back into the
        repo for committing. Null omits the snapshot command.
      '';
    };
  };

  config = lib.mkMerge [
    # Snapshot tool: keyed off repoPath, independent of whether a baseline exists
    # yet — this is how you capture the FIRST baseline from a running box. With no
    # baseline committed, OBS just starts normally and this stays available.
    (lib.mkIf (cfg.repoPath != null) {
      home.packages = [snapshotApp];
    })

    # Seed-if-absent + restore: only once a baseline has actually been committed
    # (seedSource != null). Until then there is nothing to seed and OBS behaves
    # like a plain fresh install.
    (lib.mkIf (cfg.seedSource != null) {
      # `cp -n` skips files the machine already owns; `--no-preserve=mode` drops
      # the 0444 store bit so OBS can rewrite the copy.
      home.activation.seedObsConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
        src="${toString cfg.seedSource}"
        obsDir="${obsDir}"
        run mkdir -p "$obsDir"
        for item in basic global.ini; do
          [ -e "$src/$item" ] || continue
          if [ -d "$src/$item" ]; then
            run mkdir -p "$obsDir/$item"
            run ${pkgs.coreutils}/bin/cp -rn --no-preserve=mode "$src/$item/." "$obsDir/$item/"
          elif [ ! -e "$obsDir/$item" ]; then
            run ${pkgs.coreutils}/bin/cp --no-preserve=mode "$src/$item" "$obsDir/$item"
          fi
        done
      '';

      home.packages = [restoreApp];
    })
  ];
}
