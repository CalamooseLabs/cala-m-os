# tci-run — Stream Deck "new hardcore run" spawner

Press a Stream Deck button on **broadcast** → a fresh PrismLauncher instance named
`TCI - Run #N` appears in Prism's list on **battlestation**, cloned from the Cobblemon
Initiative `.mrpack` (fresh pristine world every time). Built for resetting a
hardcore + Nuzlocke run after a death without touching the gaming PC.

## How it works

- A pristine **template** instance is built once from the `.mrpack` (Fabric 1.21.1;
  self-contained — every mod + the bundled world ship inside the pack, no downloads).
  It's rebuilt automatically whenever the pack's sha256 changes; otherwise each press
  is a fast local clone.
- `tci-run new` clones the template → `instances/tci-run-NNN` (display name
  `TCI - Run #N`), files it under the **TCI Runs** group, bumps a counter. The template
  lives in `~/.local/state/tci-run` (out of Prism's list). It's **create-only** — the
  new tile pops into Prism's live-watched list and you double-click it.
- A tiny HTTP listener (`tci-run-listener.service`, runs as `hub`) turns a Companion
  HTTP request into `tci-run new`, fired detached so the button is instant. An 8s
  debounce collapses accidental double-presses. `mmc-pack.json` is minimal — Prism
  resolves the volatile deps (intermediary/LWJGL) from its **local metadata cache**
  (populated once the pack has been launched in Prism at least once).

## One-time setup

1. `sudo nixos-rebuild switch --flake .#battlestation`
2. Put the built `.mrpack` where the tool looks: `~/TCI/` (default `mrpackPath`;
   drop the file there, or repoint `services.tci-run.mrpackPath` at a synced `dist/`).
3. Build the template: `tci-run sync` (or just let the first button press build it).
   Verify: `tci-run status` → `template_ready: true`.
4. **Companion button** (on broadcast): add a *Generic HTTP Request* action:
   - Method `GET`, URL `http://10.10.10.30:8778/new-run` (no body).
   - If a token is set, append `?token=<secret>` or add an `X-Token` header.
   - Optional second button → `http://10.10.10.30:8778/status` for a health check.
   Test it once with the rig idle so a live death isn't the first real fire.
5. **Inter-VLAN routing (required):** broadcast (studio `10.1.10.0/26`) must be able to
   reach battlestation (lab `10.10.10.30:8778`). On the router, permit
   `10.1.10.0/26 → 10.10.10.30 tcp/8778`. The listener's firewall is already scoped to
   only accept the studio subnet.

## Usage / troubleshooting

- CLI on battlestation: `tci-run new` | `tci-run sync` | `tci-run status`.
- New tile doesn't appear? Press **F5** in Prism to force a rescan (the watcher is
  usually instant; F5 is the fallback).
- After updating the modpack: drop the new `.mrpack` in `~/TCI/`. The next press
  rebuilds the template automatically (that one press is slower).

## Options (`services.tci-run.*`)

`enable`, `mrpackPath` (file or dir, default `~/TCI`), `namePrefix` (`TCI - Run #`),
`groupName` (`TCI Runs`), `port` (8778), `address`, `debounceSeconds` (8),
`allowedSources` (CIDRs the firewall accepts; set to the studio subnet here),
`tokenFile` (a file containing `TCI_RUN_TOKEN=<secret>`, loaded via EnvironmentFile —
kept out of the store), `openFirewall`.

## Notes

- battlestation root is **ext4** (no reflink) so each clone is a full copy (a few
  seconds) — fine for detached create-only. On a CoW fs (btrfs/xfs) it's instant.
- `sync` is intentionally **not** exposed over HTTP (it's a heavy rebuild); the `new`
  hot path self-heals the template on a pack change.
