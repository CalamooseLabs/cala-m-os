# Bitfocus Companion baseline for `broadcast` (TRX50-SAGE)

This directory holds the **committed Companion baseline** — a raw `db.sqlite`
(buttons, pages, surfaces, connections). It is seeded into the service's config
dir on a fresh box, then the machine owns it. Companion's config already persists
across rebuilds via its systemd `StateDirectory`, so your live edits are safe.

Wired in `../configuration.nix` via `services.bitfocus-companion.{seedDb,repoPath}`
(defined in `modules/bitfocus-companion/configuration.nix`). `seedDb` auto-activates
once `db.sqlite` exists here (`builtins.pathExists` guard) — until then, seeding and
`companion-restore` are simply absent.

## Why a raw db (not a `.companionconfig` JSON)

Companion v4.3 has **no CLI/HTTP path to import a config** — import is web-UI only.
The raw `db.sqlite` is the only artifact that can be applied programmatically. It's
robust here: it lands in the `v<major.minor>` release dir (derived from the package
version), and on upgrades Companion migrates an older db forward automatically. The
tradeoff is the file is an opaque binary — git can't diff it. If you want a
human-reviewable mirror, also export a `.companionconfig` from the UI and keep it
alongside; it's documentation only, not used by the seed.

## Round-trip (run as root — the service dir is root/StateDirectory-owned)

- **Capture the running box → repo:** `sudo companion-snapshot`
  Hot-copies the live db here via `sqlite3 .backup` (no service interruption). Then
  `git add db.sqlite` + commit.
- **Push the baseline → box (overwrite live):** `sudo companion-restore`
  Stops Companion, backs up the current db, swaps in this baseline, restarts.
- **Fresh box:** seeded automatically on first service start (only when no db
  exists in any release dir).

Bootstrap: on the box that already has your real Companion setup, run
`sudo companion-snapshot`, commit the `db.sqlite`, and it becomes the baseline.
