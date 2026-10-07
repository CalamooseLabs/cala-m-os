# OBS baseline for `broadcast` (TRX50-SAGE)

This directory holds the **committed OBS baseline** for this box. It is seeded into
`~/.config/obs-studio` on first activation and thereafter the machine owns its own
config — your live tweaks survive every `nixos-rebuild`.

Wired in `../home.nix` via `calamoose.obs.{seedSource,repoPath}` (defined in
`modules/obs-studio/home.nix`).

## Layout (populated by the snapshot command)

```
obs/
├── basic/
│   ├── profiles/<ProfileName>/…     # encoder / output / audio settings
│   └── scenes/<Collection>.json     # scene collections
└── global.ini                       # optional; opt-in, carries machine-local noise
```

## Round-trip

- **Capture the running box → repo:** `obs-config-snapshot`
  Mirrors `basic/profiles` + `basic/scenes` back here (add `--with-global` to also
  copy `global.ini` — review it, it holds window geometry/hotkeys). Then
  `git add` + commit.
- **Push the baseline → box (overwrite live):** `obs-config-restore`
  Backs up the live config to `~/.config/obs-studio.backup-<ts>.tar.gz` first, then
  **mirrors** `basic/profiles` + `basic/scenes` (removing live profiles/collections
  the baseline doesn't have — e.g. an auto-created "Untitled") and overwrites
  `global.ini`, then re-injects the stream keys (`obs-stream-keys`). Restart OBS
  to load it.
- **Fresh box:** the baseline is copied in automatically on the first rebuild
  (only where a file is absent — never clobbering machine-owned files).

Bootstrap: on the box that already has your real OBS setup, run
`obs-config-snapshot`, commit, and this becomes the baseline for reinstalls.

## Baseline decisions (re-assert these if a snapshot overwrites them)

- **`global.ini [General] BrowserHWAccel=false`** — CEF's GPU process crashing
  under Wayland/AMD takes OBS down seconds after launch, right as the browser
  sources (overlay.html, multichat) initialize; hardware acceleration off is the
  standard fix and costs little for 2D overlay pages. It must live in
  `global.ini` `[General]` (NOT `user.ini`) on OBS 30–32, and the live file can
  only be edited while OBS is closed (OBS rewrites it on exit). A snapshot taken
  with `--with-global` from a box where someone re-enabled it in Settings →
  Advanced would silently revert this.
- **Scene asset paths** point at `/home/hub/assets/<brand>/…` — seeded by
  `calamoose.obs.homeAssets` in `../home.nix` (`thecalamoose/` and `thecompany/`,
  copied from `modules/obs-kiosk/assets/<brand>/`). Keep new sources on that path
  and add the matching `homeAssets` entry, or the source renders black on a fresh
  box (seeding reproduces the path, not the file).
- **Profiles / collections:** `TheCalamoose` (→ `TheCalamoose - Coding`) and
  `The Company, Inc.` (→ `The Cobblemon Initiative`, refreshed from the
  2026-10-01 export). Main canvas: Chat Window / Starting Soon / Be Right Back /
  Gameplay / Card Opening / Only Me, with the stinger + BRB/Starting Soon media
  and full overlays. **Aitum Vertical** canvas (1080x1920): Gameplay / Card
  Opening / BRB / Starting Soon, linked to the same-named main scenes (Be Right
  Back → BRB) so switching the main scene switches the vertical one; Chat Window
  and Only Me have no vertical twin. Scene names repeat across the canvases, so
  any scripted edit must select by `uuid`/`canvas_uuid`, not `name`. History: the
  2026-09-22 snapshot dropped `Gameplay - Talking Head` + Run Counter; the
  2026-10-01 export turned the empty `Vertical Scene` into vertical Gameplay and
  dropped Conference Microphone. `global.ini` opens
  into **The Company, Inc. / The Cobblemon Initiative** by default (this box is
  primarily The Company); switch the `[Basic]` `Profile`/`SceneCollection`
  pointers to change that. These are the ONLY profiles/collections — no
  "Untitled" leftovers; `obs-config-restore` mirrors, so it prunes any that
  appear on the live box.
- **Recording paths** (`FilePath`/`RecFilePath`/`FFFilePath` in the profile)
  point at `/recordings` — the RAID0 scratch array from the machine's disko
  layout, made user-writable by a tmpfiles rule in `../configuration.nix`.
- **The Company profile streams** to Twitch (main output, Enhanced Broadcasting
  with `MultitrackExtraCanvas` = the Aitum Vertical canvas uuid
  `179cb257-40f6-4e05-9baa-b8a1be7d50a7`; it must keep matching the
  collection's `canvases` entry), YouTube (Aitum Multistream output) and
  YouTube Vertical (Aitum Vertical stream output).
- **Stream keys are never in this directory.** `service.json` is committed with
  a blank key. `obs-config-snapshot` copies each `service.json` only through a
  scrub that blanks `key`/`bearer_token`/`password`, and skips every
  `service.json*` sibling and OBS's `*.bak`/`*.tmp` save leftovers (they can
  hold old keys). A secret baked into a custom server URL is not detected, so
  review such diffs. The keys live in Proton Pass (item `Stream Keys`, fields
  `Twitch` / `YouTube` / `YouTube Vertical`). `obs-stream-keys` writes them into
  the live config when obs-kiosk launches OBS, wired by
  `calamoose.obs.streamKeys` in `../configuration.nix`. It refuses to run while
  OBS is open: OBS reads keys only at launch, and both Aitum plugins rewrite
  their config on exit. The boot-time launch usually runs before the
  post-network Proton fetch, so it uses the key already in the OBS config. After
  rotating a key, quit and relaunch OBS once the box is up. The two Aitum
  configs (`plugin_config/{aitum-multistream,vertical-canvas}/config.json`) are
  not part of this baseline either. On a fresh box the vertical one only exists
  after OBS's first run, so YouTube Vertical gets its key from the second
  launch onward.

Applying baseline changes to the ALREADY-RUNNING box: the seed is
copy-if-absent, so edits here don't reach a live config on rebuild — and
`obs-config-restore` copies from the baseline baked into the *current
generation's* script, not this directory. Sequence: `sudo nixos-rebuild switch
--flake .#broadcast` FIRST, quit OBS, then `obs-config-restore` (`--with-global`
isn't needed; restore covers `global.ini` too). And restore BEFORE the next
`obs-config-snapshot`: a snapshot from a box that hasn't been restored yet
mirrors the live (old) scenes/profiles back over hand-edits here — always
review `git diff` before committing a snapshot.
