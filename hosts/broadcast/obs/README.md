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
  overwrites the baseline files. Restart OBS to load it.
- **Fresh box:** the baseline is copied in automatically on the first rebuild
  (only where a file is absent — never clobbering machine-owned files).

Bootstrap: on the box that already has your real OBS setup, run
`obs-config-snapshot`, commit, and this becomes the baseline for reinstalls.
