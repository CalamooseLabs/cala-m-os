# Bitfocus Companion baseline for `broadcast` (TRX50-SAGE)

This directory holds the **committed Companion baseline** — a raw `db.sqlite`
(buttons, pages, surfaces, connections). It is seeded into the service's config
dir on a fresh box, then the machine owns it. Companion's config already persists
across rebuilds via its systemd `StateDirectory`, so your live edits are safe.

Wired in `../configuration.nix` via `services.bitfocus-companion.{seedDb,repoPath}`
(defined in `modules/bitfocus-companion/configuration.nix`), inside the host's
non-install branch. `seedDb` auto-activates once `db.sqlite` exists here
(`builtins.pathExists` guard) — until then, seeding and `companion-restore` are
simply absent.

## Connection modules (the "Unknown module" fix)

Companion 4.x bundles **no connection modules** — each is normally installed from
the Bitfocus module store into `/var/lib/bitfocus-companion/modules/`, which a
reinstall wipes. The db pins each connection to an **exact** module version
(`moduleVersionId`), the startup lookup is exact-match, and Companion never
auto-installs — so on a fresh box every seeded connection used to come up
"Unknown module" until deleted and re-added by hand.

Fixed by `services.bitfocus-companion.connectionModules` in
`../configuration.nix`: the exact pinned versions are fetched (hash-locked) from
the store CDN at build time and copied into the modules dir before startup,
byte-identical to a store install. **Keep that list in lockstep with this db** —
if a snapshot/export ever changes a connection's `moduleVersionId` (e.g. you
updated a module through the UI), update the pinned entry, or the next reinstall
regresses to "Unknown module version". Check the pins with:

    jq -r '.instances[] | "\(.moduleId)-\(.moduleVersionId)"' db.companionconfig

## Secrets

The committed `db.sqlite` is **scrubbed** of the OBS WebSocket password (the `pass`
field on the `obs-studio` connection is blank) so no cleartext credential lands in
git — and nothing has to re-supply it, because OBS runs its websocket with
**authentication disabled**. Port 4455 is not opened in the firewall (only 9998/SRT
is) and this is a single-user box, so the websocket is localhost-only and Companion
connects over loopback with no password. OBS's side is seeded (auth off, server on)
by `../home.nix` → `plugin_config/obs-websocket/config.json`.

So there is no OBS-websocket secret to manage. If you ever re-enable auth, set a
matching password on both the OBS server and the Companion `obs` connection, and keep
it out of git (e.g. `calamoose.secrets` + Proton Pass, injected at runtime).

Note: `companion-snapshot` copies the live db verbatim. If you later add a Companion
connection that stores a password, scrub it from the snapshot before committing. The
same goes for an exported `.companionconfig` — exports embed connection config, so
verify every connection's `secrets` AND `config` are clean before committing one
(the committed `db.companionconfig` was checked: obs is loopback/no-pass,
generic-http has none).

The **twitch-api** connection keeps its OAuth `accessToken`/`refreshToken` in plain
`config` (not `secrets`!) — both are scrubbed to `""` in the committed export and
db. After a reinstall/restore, re-authenticate the Twitch connection in the
Companion UI; until then it will show a connection error (not an unknown module).

**Stream keys** (Twitch + YouTube via Aitum) are intentionally not stored here — they
rotate and stay in OBS/Aitum on the box; re-enter them after a reinstall.

## Why a raw db (not a `.companionconfig` JSON)

Companion v4.3 has **no CLI/HTTP path to import a config** — import is web-UI only.
The raw `db.sqlite` is the only artifact that can be applied programmatically. It's
robust here: it lands in the `v<major.minor>` release dir (derived from the package
version), and on upgrades Companion migrates an older db forward automatically. The
tradeoff is the file is an opaque binary — git can't diff it.

`db.companionconfig` is the human-reviewable mirror of the committed db (a "full"
export from the UI, 2026-09-22: pages HOME/Scenes/TCI, obs + generic-http + twitch
connections, `deaths` custom variable, Stream Deck Neo surface; Twitch tokens
scrubbed). It's documentation, not used by the seed —
but the db CAN be rebuilt from an export without touching the box:

    cp db.sqlite /tmp/db.sqlite && chmod +w /tmp/db.sqlite   # keeps main/userconfig + cloud
    jq -r -f import-companionconfig.jq db.companionconfig | sqlite3 /tmp/db.sqlite
    # verify, then copy back over db.sqlite

`import-companionconfig.jq` replaces pages/controls/instances/surfaces/custom
variables from the export and preserves everything else. Written against the v4.3
db layout
(`page_config_version` 11) — re-verify the shapes after a major Companion bump,
e.g. by booting `bitfocus-companion --config-dir <tmpdir>` against the result.

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
