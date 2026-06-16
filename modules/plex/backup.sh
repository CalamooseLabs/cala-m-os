#!/usr/bin/env bash
#
# plex-backup — snapshot Plex's identity + databases to the NAS backup share.
#
# Paths mirror modules/plex/configuration.nix:
#   data dir     : /var/lib/plex   (services.plex.dataDir default)
#   backup share : /mnt/backup     (nfs.backup.plex, mounted by the module)
#
# Layout written to the share (matches the legacy, non-NixOS server):
#   /mnt/backup/Preferences.xml                 latest server identity + token
#   /mnt/backup/automated/nixos-plex-<stamp>/   verified DB snapshots (rotated)
#
# Each snapshot is staged into a hidden ".partial" dir and only renamed into
# place once every database present on disk has been backed up AND passes an
# integrity check, so a half-written snapshot is never visible to plex-restore.
#
# Runs as the `plex` user (see the systemd unit) so it can read the live data
# dir; it therefore needs write access to the backup share.

set -euo pipefail

PMS="/var/lib/plex/Plex Media Server"
DB_DIR="$PMS/Plug-in Support/Databases"
BACKUP="/mnt/backup"
AUTO_DIR="$BACKUP/automated"
RETENTION=7

DATABASES=(
  "com.plexapp.plugins.library.db"
  "com.plexapp.plugins.library.blobs.db"
)

if ! mountpoint -q "$BACKUP"; then
  echo "plex-backup: backup share $BACKUP is not mounted; aborting." >&2
  exit 1
fi

mkdir -p "$AUTO_DIR"

# Clear staging dirs left behind by a previously interrupted run. The leading
# dot keeps them out of the 'nixos-plex-*' snapshot namespace regardless.
rm -rf "$AUTO_DIR"/.nixos-plex-*.partial

# 1. Preferences.xml -> share root, written atomically (temp + rename).
prefs_present=0
if [ -f "$PMS/Preferences.xml" ]; then
  tmp="$(mktemp "$BACKUP/.Preferences.xml.XXXXXX")"
  cp -f "$PMS/Preferences.xml" "$tmp"
  mv -f "$tmp" "$BACKUP/Preferences.xml"
  prefs_present=1
  echo "plex-backup: saved Preferences.xml"
else
  echo "plex-backup: WARNING Preferences.xml not found under $PMS" >&2
fi

# 2. Consistent + verified SQLite snapshot of the databases (safe while Plex
#    is running, since .backup reads committed WAL pages).
stamp="$(date +%Y%m%d-%H%M%S)"
dest="$AUTO_DIR/nixos-plex-$stamp"
staging="$AUTO_DIR/.nixos-plex-$stamp.partial"
rm -rf "$staging"
mkdir -p "$staging"

expected=0
saved=0
for db in "${DATABASES[@]}"; do
  [ -f "$DB_DIR/$db" ] || continue
  expected=$((expected + 1))

  if ! sqlite3 "$DB_DIR/$db" ".backup '$staging/$db'"; then
    echo "plex-backup: ERROR sqlite .backup of $db failed" >&2
    continue
  fi

  check="$(sqlite3 "$staging/$db" 'PRAGMA quick_check;' 2>&1 || echo 'check-failed')"
  if [ "$check" != "ok" ]; then
    echo "plex-backup: ERROR integrity check of $db snapshot failed: $check" >&2
    continue
  fi

  saved=$((saved + 1))
done

# A database present on disk that we could not back up means this snapshot is
# incomplete: discard it and fail loudly so the timer/journal shows the error
# rather than rotating a good snapshot out in favour of a broken one.
if [ "$saved" -lt "$expected" ]; then
  echo "plex-backup: ERROR only $saved of $expected database(s) backed up; discarding snapshot." >&2
  rm -rf "$staging"
  exit 1
fi

if [ "$expected" -gt 0 ]; then
  # Keep a copy of Preferences.xml inside the snapshot so it is self-contained
  # (identity + databases from one backup run).
  if [ -f "$PMS/Preferences.xml" ]; then
    cp -f "$PMS/Preferences.xml" "$staging/Preferences.xml"
  fi
  mv -f "$staging" "$dest"
  echo "plex-backup: wrote snapshot $dest ($saved database(s))"
else
  rm -rf "$staging"
  echo "plex-backup: no databases found under $DB_DIR (nothing to snapshot)." >&2
  if [ "$prefs_present" -eq 0 ]; then
    echo "plex-backup: ERROR nothing was backed up (no Preferences.xml, no databases)." >&2
    exit 1
  fi
fi

# 3. Retention — keep only the newest $RETENTION completed snapshots.
mapfile -t snapshots < <(find "$AUTO_DIR" -mindepth 1 -maxdepth 1 -type d -name 'nixos-plex-*' ! -name '*.partial' | sort)
total=${#snapshots[@]}
if [ "$total" -gt "$RETENTION" ]; then
  prune=$((total - RETENTION))
  for ((i = 0; i < prune; i++)); do
    echo "plex-backup: pruning old snapshot ${snapshots[i]}"
    rm -rf "${snapshots[i]}"
  done
fi

echo "plex-backup: done."
