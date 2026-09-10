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
  `global.ini`. Restart OBS to load it.
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
  `The Company, Inc.` (→ `The Cobblemon Initiative`: Chat Window / Starting Soon /
  Be Right Back / Gameplay / Gameplay - Talking Head / Card Opening, with the
  stinger + BRB/Starting Soon media and full/paper overlays). `global.ini` opens
  into **The Company, Inc. / The Cobblemon Initiative** by default (this box is
  primarily The Company); switch the `[Basic]` `Profile`/`SceneCollection`
  pointers to change that. These are the ONLY profiles/collections — no
  "Untitled" leftovers; `obs-config-restore` mirrors, so it prunes any that
  appear on the live box.
- **Recording paths** (`FilePath`/`RecFilePath`/`FFFilePath` in the profile)
  point at `/recordings` — the RAID0 scratch array from the machine's disko
  layout, made user-writable by a tmpfiles rule in `../configuration.nix`.

Applying baseline changes to the ALREADY-RUNNING box: the seed is
copy-if-absent, so edits here don't reach a live config on rebuild — and
`obs-config-restore` copies from the baseline baked into the *current
generation's* script, not this directory. Sequence: `sudo nixos-rebuild switch
--flake .#broadcast` FIRST, quit OBS, then `obs-config-restore` (`--with-global`
isn't needed; restore covers `global.ini` too). And restore BEFORE the next
`obs-config-snapshot`: a snapshot from a box that hasn't been restored yet
mirrors the live (old) scenes/profiles back over hand-edits here — always
review `git diff` before committing a snapshot.
