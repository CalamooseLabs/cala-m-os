################################################################
#                                                              #
#   TCI Run — Stream Deck "new hardcore run" instance spawner  #
#                                                              #
#   Clones a pristine PrismLauncher template (built from the   #
#   Cobblemon Initiative .mrpack) into a fresh, uniquely       #
#   named instance ("TCI - Run #N") on demand. A tiny HTTP     #
#   listener lets the broadcast box's Bitfocus Companion fire  #
#   it from a Stream Deck button after a death. Create-only:   #
#   the new instance pops into Prism's live-watched list and   #
#   you double-click it. If a tile doesn't appear, press F5    #
#   in Prism to force a rescan.                                #
#                                                              #
#   Relies on Prism's local metadata cache holding the pack's  #
#   Minecraft + Fabric components (guaranteed once the pack    #
#   has been launched in Prism at least once) — the generated  #
#   mmc-pack.json is minimal and Prism resolves the rest.      #
#                                                              #
################################################################
{
  config,
  lib,
  pkgs,
  cala-m-os,
  ...
}: let
  cfg = config.services.tci-run;
  # Intentionally tracks cfg.user; cfg.user's own default is a static global, so
  # no recursion. Feeds the path defaults + the service HOME.
  home = "/home/${cfg.user}";

  # --- The worker CLI: build-template-if-changed, then clone a fresh run. ---
  # Everything the Stream Deck hits ends up here. `new` is the hot path (a clone
  # of the pristine template — a reflink where the fs supports CoW, a full copy
  # otherwise); `sync` (re)builds the template from the .mrpack and only runs
  # when the pack's hash changes. Both mutate shared state, so the dispatch holds
  # an flock across them to serialize concurrent (double-press) invocations.
  tci-run = pkgs.writeShellApplication {
    name = "tci-run";
    runtimeInputs = [pkgs.coreutils pkgs.unzip pkgs.jq pkgs.gnused pkgs.findutils pkgs.curl pkgs.util-linux];
    text = ''
      PRISM_DIR="${cfg.prismDir}"
      INSTANCES="$PRISM_DIR/instances"
      STATE_DIR="${cfg.stateDir}"
      MRPACK_SRC="${cfg.mrpackPath}"
      NAME_PREFIX="${cfg.namePrefix}"
      GROUP_NAME="${cfg.groupName}"
      FOLDER_PREFIX="tci-run-"

      TEMPLATE="$STATE_DIR/template"
      HASH_FILE="$STATE_DIR/template.hash"
      COUNTER_FILE="$STATE_DIR/counter"

      log() { printf '[tci-run] %s\n' "$*" >&2; }

      # Resolve the mrpack: a direct file, or the newest *.mrpack in a directory.
      resolve_mrpack() {
        if [ -z "$MRPACK_SRC" ]; then return 1; fi
        if [ -f "$MRPACK_SRC" ]; then printf '%s\n' "$MRPACK_SRC"; return 0; fi
        if [ -d "$MRPACK_SRC" ]; then
          local newest
          newest="$(find "$MRPACK_SRC" -maxdepth 1 -type f -name '*.mrpack' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-)"
          if [ -n "$newest" ]; then printf '%s\n' "$newest"; return 0; fi
        fi
        return 1
      }

      # Build a pristine template instance from the mrpack. Self-contained packs
      # (files:[] — everything under overrides/) need no network; referenced
      # files[] are still downloaded + sha1-verified for generality.
      build_template() {
        local mrpack="$1"
        log "building template from $mrpack"
        local tmp="$STATE_DIR/template.tmp"
        rm -rf "$tmp"
        mkdir -p "$tmp/_extract" "$tmp/minecraft"
        if ! unzip -q "$mrpack" -d "$tmp/_extract"; then
          log "failed to unzip $mrpack (corrupt/truncated?)"
          return 1
        fi

        local index="$tmp/_extract/modrinth.index.json"
        if [ ! -f "$index" ]; then log "no modrinth.index.json in mrpack"; return 1; fi

        local mc fabric
        mc="$(jq -r '.dependencies["minecraft"] // empty' "$index")"
        fabric="$(jq -r '.dependencies["fabric-loader"] // empty' "$index")"
        if [ -z "$mc" ]; then log "mrpack missing minecraft version"; return 1; fi
        if [ -z "$fabric" ]; then log "not a Fabric pack (no fabric-loader in deps) — unsupported"; return 1; fi

        # overrides/ (and client-overrides/) become the instance's minecraft/ dir.
        if [ -d "$tmp/_extract/overrides" ]; then cp -a "$tmp/_extract/overrides/." "$tmp/minecraft/"; fi
        if [ -d "$tmp/_extract/client-overrides" ]; then cp -a "$tmp/_extract/client-overrides/." "$tmp/minecraft/"; fi

        # Download any CDN-referenced files (none for a self-contained pack).
        local nfiles
        nfiles="$(jq '.files | length' "$index")"
        if [ "$nfiles" -gt 0 ]; then
          log "downloading $nfiles referenced file(s)"
          local tsv
          tsv="$(jq -r '.files[] | select((.env.client // "required") != "unsupported") | [.path, (.downloads[0] // ""), (.hashes.sha1 // "")] | @tsv' "$index")"
          while IFS="$(printf '\t')" read -r fpath furl fsha; do
            if [ -z "$furl" ]; then continue; fi
            local dest="$tmp/minecraft/$fpath"
            mkdir -p "$(dirname "$dest")"
            curl -fsSL "$furl" -o "$dest"
            if [ -n "$fsha" ]; then
              if ! printf '%s  %s\n' "$fsha" "$dest" | sha1sum -c - >/dev/null 2>&1; then
                log "sha1 mismatch for $fpath"; return 1
              fi
            fi
          done <<< "$tsv"
        fi

        # Pristine-world guard: a stale session.lock (or a pack accidentally built
        # from a dirty world) would break the "fresh world every run" promise.
        if [ -d "$tmp/minecraft/saves" ]; then
          find "$tmp/minecraft/saves" -type f -name session.lock -delete 2>/dev/null || true
        fi

        # Brand the run tiles with the pack icon if shipped. Prism reads instance
        # icons from its shared icons/ dir keyed by iconKey (NOT minecraft/icon.png).
        local iconkey="default"
        if [ -f "$tmp/minecraft/icon.png" ]; then
          mkdir -p "$PRISM_DIR/icons"
          cp -f "$tmp/minecraft/icon.png" "$PRISM_DIR/icons/tci-run.png"
          iconkey="tci-run"
        fi

        # Minimal, version-derived Prism metadata. Prism auto-resolves the
        # volatile deps (intermediary mappings, LWJGL) from these two on load.
        jq -n --arg mc "$mc" --arg fl "$fabric" '{
          formatVersion: 1,
          components: [
            {uid: "net.minecraft", version: $mc, important: true},
            {uid: "net.fabricmc.fabric-loader", version: $fl}
          ]
        }' > "$tmp/mmc-pack.json"

        # Template cfg. name= is overwritten per clone; keep it otherwise lean so
        # Prism fills sane defaults (AutomaticJava, etc).
        {
          printf '[General]\n'
          printf 'ConfigVersion=1.3\n'
          printf 'InstanceType=OneSix\n'
          printf 'iconKey=%s\n' "$iconkey"
          printf 'name=TCI Template\n'
        } > "$tmp/instance.cfg"

        rm -rf "$tmp/_extract"

        # Swap the freshly built template in atomically.
        local h
        h="$(sha256sum "$mrpack" | cut -d' ' -f1)"
        rm -rf "$STATE_DIR/template.old"
        if [ -d "$TEMPLATE" ]; then mv "$TEMPLATE" "$STATE_DIR/template.old"; fi
        mv "$tmp" "$TEMPLATE"
        rm -rf "$STATE_DIR/template.old"
        printf '%s\n' "$h" > "$HASH_FILE"
        log "template ready (minecraft $mc / fabric $fabric)"
      }

      # Rebuild the template only if the mrpack changed since last build.
      ensure_template() {
        local mrpack
        if ! mrpack="$(resolve_mrpack)"; then
          log "no mrpack found at: $MRPACK_SRC"
          return 1
        fi
        local h
        h="$(sha256sum "$mrpack" | cut -d' ' -f1)"
        if [ -d "$TEMPLATE" ] && [ -f "$HASH_FILE" ] && [ "$(cat "$HASH_FILE")" = "$h" ]; then
          return 0
        fi
        build_template "$mrpack"
      }

      # Read the counter, sanitizing anything non-numeric (a corrupt/empty file
      # must not abort the run under set -u), and return the next value.
      next_number() {
        local n=0
        if [ -f "$COUNTER_FILE" ]; then read -r n < "$COUNTER_FILE" || n=0; fi
        case "$n" in "" | *[!0-9]*) n=0 ;; esac
        n=$((n + 1))
        printf '%s\n' "$n" > "$COUNTER_FILE"
        printf '%s\n' "$n"
      }

      # Register the new instance under a Prism group so runs stay tidy in the UI.
      add_to_group() {
        local folder="$1"
        local f="$INSTANCES/instgroups.json"
        local tmp="$f.tmp.$$"
        if [ ! -f "$f" ]; then printf '{"formatVersion":"1","groups":{}}' > "$f"; fi
        if jq --arg g "$GROUP_NAME" --arg i "$folder" '
              .groups[$g].hidden = (.groups[$g].hidden // false)
              | .groups[$g].instances = (((.groups[$g].instances // []) + [$i]) | unique)
            ' "$f" > "$tmp" 2>/dev/null; then
          mv "$tmp" "$f"
        else
          log "group update failed (non-fatal)"; rm -f "$tmp"
        fi
      }

      new_run() {
        if ! ensure_template; then
          log "no template; place an mrpack in $MRPACK_SRC and run 'tci-run sync'"
          return 1
        fi

        local n folder display build cfg
        n="$(next_number)"
        folder="$(printf '%s%03d' "$FOLDER_PREFIX" "$n")"
        display="$NAME_PREFIX$n"
        build="$STATE_DIR/build-$folder"

        rm -rf "$build"
        # Built outside instances/ then atomically renamed in, so a running Prism
        # never sees a half-written instance. Reflink on CoW filesystems; a plain
        # copy (a few seconds) elsewhere — fine for detached create-only.
        cp -aT --reflink=auto "$TEMPLATE" "$build"

        # Set the display name with printf (takes the value literally — immune to
        # any '/','&','\' an operator might put in namePrefix, unlike sed). Strip
        # stale name/play-time lines from the template first, then append fresh.
        cfg="$build/instance.cfg"
        if [ -f "$cfg" ]; then
          grep -vE '^(name|lastLaunchTime|lastTimePlayed|totalTimePlayed)=' "$cfg" > "$cfg.new" || true
          mv "$cfg.new" "$cfg"
        else
          printf '[General]\nConfigVersion=1.3\nInstanceType=OneSix\niconKey=default\n' > "$cfg"
        fi
        printf 'name=%s\n' "$display" >> "$cfg"

        mkdir -p "$INSTANCES"
        # File the group membership BEFORE the folder appears, so Prism's watcher
        # sees the instance land already grouped (no ungrouped flash).
        add_to_group "$folder"
        rm -rf "''${INSTANCES:?}/$folder"
        mv "$build" "$INSTANCES/$folder"
        printf '%s\n' "$display" > "$STATE_DIR/last"
        log "created '$display' -> $INSTANCES/$folder"
        printf '%s\n' "$display"
      }

      status() {
        local n=0 last="" tpl=false
        if [ -f "$COUNTER_FILE" ]; then read -r n < "$COUNTER_FILE" || n=0; fi
        case "$n" in "" | *[!0-9]*) n=0 ;; esac
        if [ -f "$STATE_DIR/last" ]; then last="$(< "$STATE_DIR/last")"; fi
        if [ -d "$TEMPLATE" ]; then tpl=true; fi
        jq -n --argjson c "$n" --arg l "$last" --argjson t "$tpl" \
          '{counter: $c, last: $l, template_ready: $t}'
      }

      mkdir -p "$STATE_DIR"
      case "''${1:-new}" in
        new)
          exec 9> "$STATE_DIR/.lock"
          flock 9
          new_run
          ;;
        sync)
          exec 9> "$STATE_DIR/.lock"
          flock 9
          if mrpack="$(resolve_mrpack)"; then build_template "$mrpack"; else log "no mrpack at $MRPACK_SRC"; exit 1; fi
          ;;
        status) status ;;
        *) log "usage: tci-run {new|sync|status}"; exit 2 ;;
      esac
    '';
  };

  # --- The HTTP listener Companion pokes. Fires `tci-run new` detached so the
  #     button response is instant even on the rare press that rebuilds the
  #     template; the fresh instance then just pops into Prism's list. A short
  #     debounce collapses accidental double-presses into one run. `sync` is
  #     deliberately NOT exposed over HTTP (heavy rebuild) — it's CLI-only and
  #     the `new` hot path already self-heals the template on a pack change. ---
  listenerPy = pkgs.writeText "tci-run-listener.py" ''
    import json, os, subprocess, sys, threading, time
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
    from urllib.parse import urlparse, parse_qs

    TCI_RUN = "${tci-run}/bin/tci-run"
    TOKEN = os.environ.get("TCI_RUN_TOKEN", "")
    PORT = int(os.environ.get("TCI_RUN_PORT", "${toString cfg.port}"))
    ADDR = os.environ.get("TCI_RUN_ADDR", "${cfg.address}")
    DEBOUNCE = float(os.environ.get("TCI_RUN_DEBOUNCE", "${toString cfg.debounceSeconds}"))

    _lock = threading.Lock()
    _last = 0.0

    def fire_new():
        global _last
        with _lock:
            now = time.monotonic()
            if now - _last < DEBOUNCE:
                return False
            _last = now
        subprocess.Popen([TCI_RUN, "new"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                         start_new_session=True)
        return True

    class Handler(BaseHTTPRequestHandler):
        def _send(self, code, obj):
            body = json.dumps(obj).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _authed(self, q):
            if not TOKEN:
                return True
            tok = q.get("token", [""])[0] or self.headers.get("X-Token", "")
            return tok == TOKEN

        def do_GET(self):
            u = urlparse(self.path)
            q = parse_qs(u.query)
            if not self._authed(q):
                return self._send(403, {"ok": False, "error": "forbidden"})
            if u.path in ("/new-run", "/new", "/"):
                fired = fire_new()
                return self._send(200, {"ok": True, "action": "new-run" if fired else "debounced"})
            if u.path == "/status":
                try:
                    out = subprocess.run([TCI_RUN, "status"], capture_output=True, text=True, timeout=10)
                    return self._send(200, json.loads(out.stdout or "{}"))
                except Exception as e:
                    return self._send(500, {"ok": False, "error": str(e)})
            return self._send(404, {"ok": False, "error": "not found"})

        do_POST = do_GET

        def log_message(self, fmt, *a):
            sys.stderr.write("[tci-run-listener] " + (fmt % a) + "\n")

    if __name__ == "__main__":
        ThreadingHTTPServer((ADDR, PORT), Handler).serve_forever()
  '';
in {
  options.services.tci-run = {
    enable = lib.mkEnableOption "TCI run spawner + Stream Deck HTTP trigger";

    user = lib.mkOption {
      type = lib.types.str;
      default = cala-m-os.globals.defaultUser;
      description = "User that owns the PrismLauncher data and runs the listener.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = cala-m-os.globals.userGroup;
      description = "Primary group of {option}`user`.";
    };

    prismDir = lib.mkOption {
      type = lib.types.str;
      default = "${home}/.local/share/PrismLauncher";
      description = "PrismLauncher data directory (holds instances/).";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "${home}/.local/state/tci-run";
      description = "Where the pristine template, run counter, and hash live.";
    };

    mrpackPath = lib.mkOption {
      type = lib.types.str;
      default = "${home}/TCI";
      description = ''
        Path to the Cobblemon Initiative .mrpack, or a directory to scan for the
        newest *.mrpack. The template is rebuilt whenever this file's hash changes.
      '';
    };

    namePrefix = lib.mkOption {
      type = lib.types.str;
      default = "TCI - Run #";
      description = "Display-name prefix; the run number is appended.";
    };

    groupName = lib.mkOption {
      type = lib.types.str;
      default = "TCI Runs";
      description = "PrismLauncher group the spawned instances are filed under.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8778;
      description = "TCP port the HTTP trigger listens on.";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Address the HTTP trigger binds to.";
    };

    debounceSeconds = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Collapse repeat /new-run triggers within this many seconds into one (double-press guard).";
    };

    tokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/agenix/tci-run-token";
      description = ''
        Optional file containing a single line `TCI_RUN_TOKEN=<secret>`, loaded via
        systemd EnvironmentFile (kept out of the world-readable store). When set,
        requests must carry the token as `?token=…` or an `X-Token` header. Null
        (default) relies on firewall scoping instead.
      '';
    };

    allowedSources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["10.1.10.0/26"];
      description = ''
        When non-empty (and {option}`openFirewall`), the port is opened ONLY to
        these source CIDRs/IPs (iptables, or nftables if enabled) instead of the
        whole LAN. Empty opens {option}`port` on all interfaces.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open {option}`port` in the firewall (scoped by {option}`allowedSources` when set).";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [tci-run];

    # Own the state + mrpack drop dirs regardless of who first invokes the CLI.
    systemd.tmpfiles.rules =
      ["d ${cfg.stateDir} 0755 ${cfg.user} ${cfg.group} - -"]
      ++ lib.optional (!lib.hasSuffix ".mrpack" cfg.mrpackPath)
      "d ${cfg.mrpackPath} 0755 ${cfg.user} ${cfg.group} - -";

    networking.firewall = lib.mkIf cfg.openFirewall (
      if cfg.allowedSources == []
      then {allowedTCPPorts = [cfg.port];}
      else if config.networking.nftables.enable
      then {extraInputRules = lib.concatMapStringsSep "\n" (s: "ip saddr ${s} tcp dport ${toString cfg.port} accept") cfg.allowedSources;}
      else {extraCommands = lib.concatMapStringsSep "\n" (s: "iptables -A nixos-fw -p tcp -s ${s} --dport ${toString cfg.port} -j nixos-fw-accept") cfg.allowedSources;}
    );

    systemd.services.tci-run-listener = {
      description = "TCI run trigger (PrismLauncher instance spawner)";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 ${listenerPy}";
        User = cfg.user;
        Group = cfg.group;
        Environment = [
          "HOME=${home}"
          "TCI_RUN_PORT=${toString cfg.port}"
          "TCI_RUN_ADDR=${cfg.address}"
          "TCI_RUN_DEBOUNCE=${toString cfg.debounceSeconds}"
        ];
        EnvironmentFile = lib.mkIf (cfg.tokenFile != null) cfg.tokenFile;
        Restart = "on-failure";
        RestartSec = 3;

        # Light hardening — safe for a service that unzips/copies large trees under
        # the user's home and spawns the detached CLI. Deliberately NOT ProtectHome
        # / ProtectSystem=strict, which would block the clone into ~/.local.
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        LockPersonality = true;
        RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
      };
    };
  };
}
