{
  config,
  lib,
  pkgs,
  betaPkgsFor,
  ...
}: let
  # Beta-aware (the reference for the pattern): what this module installs comes
  # from `betaPkgsFor "obs-studio"` — the main nixpkgs normally, the
  # nixpkgs-beta input when a host or user profile sets
  # `calamoose.modules."obs-studio".beta = true` (see hosts/_core/options.nix;
  # the betaAware declaration below makes the flag loud when this module isn't
  # enrolled). Plain `pkgs` stays bound to the MAIN pin for
  # the driver-coupled exception below; a module with no such exception can
  # simply shadow (`pkgs = betaPkgsFor "<name>";` — see ./home.nix). Not
  # affected either way: the v4l2loopback kernel module comes from
  # config.boot.kernelPackages, and the kernel is never split across channels.
  # (programs.obs-studio assembles finalPackage with the main pin's wrapOBS —
  # a pure symlinkJoin+env wrapper, safe to mix.)
  obsPkgs = betaPkgsFor "obs-studio";

  # ---- Stream-key injection (calamoose.obs.streamKeys) ----
  # OBS keeps stream keys in three different files, each with its own rules:
  #   service    basic/profiles/<dir>/service.json  .settings.key (main output)
  #   multistream plugin_config/aitum-multistream/config.json — outputs under
  #              the profile's DISPLAY name (basic.ini [General] Name, exact match)
  #   vertical   plugin_config/vertical-canvas/config.json — GLOBAL (not
  #              per-profile) canvas[0].stream_outputs
  # OBS reads all of them only at launch, and both Aitum plugins rewrite their
  # config from memory on exit — so keys are injected only while OBS is NOT
  # running (obs-kiosk runs it right before launching OBS). multistream outputs
  # are matched by a substring of their ingest server (`match`), so hand-made
  # outputs (and a YouTube primary+backup pair, which share one key) all get the
  # key; the GLOBAL vertical list is matched by output name (`create.name`) so
  # another brand's output is never re-keyed; `create` adds an output when none
  # qualifies. Keys come from
  # root-provisioned secret files (calamoose.secrets, owner = the OBS user) and
  # never touch argv: jq reads them with --rawfile and strips the trailing
  # newline pass-cli prints.
  streamKeysCfg = config.calamoose.obs.streamKeys;
  streamKeysSpec = pkgs.writeText "obs-stream-keys.json" (builtins.toJSON (lib.mapAttrsToList (label: t: {
      inherit label;
      inherit (t) target keyFile profile;
      match = lib.toLower t.match;
      create = t.create;
    })
    streamKeysCfg));

  obsStreamKeys = pkgs.writeShellApplication {
    name = "obs-stream-keys";
    runtimeInputs = [pkgs.coreutils pkgs.gawk pkgs.jq pkgs.procps];
    text = ''
      obsDir="''${XDG_CONFIG_HOME:-$HOME/.config}/obs-studio"
      spec=${streamKeysSpec}
      wait=0
      case "''${1:-}" in
        "") ;;
        --wait)
          wait="''${2:-}"
          if ! [[ $wait =~ ^[0-9]+$ ]]; then
            echo "obs-stream-keys: --wait needs a whole number of seconds" >&2
            exit 2
          fi
          wait=$((10#$wait)) ;;
        *)
          echo "usage: obs-stream-keys [--wait SECONDS]" >&2
          echo "  Injects the configured stream keys into the OBS config. OBS must be closed." >&2
          echo "  --wait: when a target has never been given a key and its secret is not" >&2
          echo "          fetched yet (fresh box, secrets still arriving), wait up to N s." >&2
          exit 2 ;;
      esac

      # Same match as obs-kiosk: the MAIN obs process by kernel name (comm), never
      # argv — the wrapper chain rewrites argv0 (see modules/obs-kiosk).
      obsRunning() { pgrep -u "$(id -un)" -x '\.?obs(-wrapped)?' >/dev/null 2>&1; }
      if obsRunning; then
        echo "obs-stream-keys: OBS is running — quit it first (OBS reads keys only at launch, and the Aitum plugins overwrite their config on exit)" >&2
        exit 1
      fi

      # The jq programs below are single-quoted on purpose ($m, $k… are jq vars).
      # shellcheck disable=SC2016
      common='
        def m: ascii_downcase | contains($m);
        def k: $k | gsub("\\s"; "");
        # Aitum Multistream falls back to a legacy "server" when stream_server is empty.
        def srv: if (.stream_server // "") != "" then .stream_server else (.server // "") end;
        def new($key): {name: $c.name, stream_server: $c.server, stream_key: $key};
        # multistream (per-profile): every matching output is ours — e.g. a
        # YouTube primary + backup pair sharing one key.
        def upsertAll($key):
          if any(.[]; srv | m)
          then map(if srv | m then .stream_key = $key else . end)
          elif $c == null then error("no output matches \"\($m)\" and create is unset")
          elif any(.[]; .name == $c.name) then error("an output named \"\($c.name)\" exists but its server does not match \"\($m)\"")
          else . + [new($key)] end;
        # vertical (GLOBAL, shared with other brands): only the output NAMED
        # create.name is ours, so a YouTube output of another channel is never
        # touched. A matching output that already holds exactly this key (set
        # up by hand before injection existed) is claimed once by renaming it,
        # so a later key rotation still finds it instead of adding a duplicate.
        def upsertNamed($key):
          (if any(.[]; .name == $c.name) then .
           else (first(range(length) as $i
                   | select(.[$i] | (srv | m) and .stream_key == $key) | $i) // null) as $i
             | if $i == null then . else .[$i].name = $c.name end end)
          | if any(.[]; .name == $c.name and (srv | m))
            then map(if .name == $c.name then .stream_key = $key else . end)
            elif any(.[]; .name == $c.name) then error("an output named \"\($c.name)\" exists but its server does not match \"\($m)\"")
            else . + [new($key) + {enabled: true}] end;
        def upsert($key): if $t == "vertical" then upsertNamed($key) else upsertAll($key) end;
        # "Never keyed" heuristic for --wait (the key itself is not known yet):
        # no output that would be ours, or one of ours still blank.
        def pending:
          if $t == "vertical"
          then (any(.[]; .name == $c.name) | not) or any(.[]; .name == $c.name and ((.stream_key // "") == ""))
          else (any(.[]; srv | m) | not) or any(.[]; (srv | m) and ((.stream_key // "") == "")) end;
      '
      # shellcheck disable=SC2016
      declare -A inject=(
        [service]='
          if ((.settings.service // "") + " " + (.settings.server // "")) | m
          then .settings.key = k
          else error("the profile streams to \(.settings.service // .settings.server // "?"), not \"\($m)\"") end'
        [multistream]='
          .partner_block //= 0
          | .profiles = ((.profiles // [])
              | if any(.[]; .name == $p) then . else . + [{name: $p}] end
              | map(if .name == $p then .outputs = ((.outputs // []) | upsert(k)) else . end))'
        [vertical]='
          if (.canvas // []) == [] then error("no canvas yet (launch OBS once)") else . end
          | .canvas[0] |= (
              # Fold a pre-1.6 single output into stream_outputs, as the plugin does on load.
              (if (.stream_outputs // []) == [] and (.stream_server // "") != ""
               then .stream_outputs = [{name: "", stream_server: .stream_server, stream_key: (.stream_key // ""), enabled: true}]
                    | del(.stream_server, .stream_key)
               else . end)
              | (.stream_outputs // []) as $before
              | .stream_outputs = ($before | upsert(k))
              # Creating an output skips the plugin dialog that would store a
              # bitrate; with none (0) the vertical stream falls back to the
              # profile encoder (40 Mbps CBR here) whenever Enhanced
              # Broadcasting is not live. Use the dialog default, never
              # overriding a value the box already has.
              | if (.stream_outputs | length) > ($before | length)
                   and (.streaming_video_bitrate // 0) == 0 and (.video_bitrate // 0) == 0
                then .streaming_video_bitrate = 6000 else . end)'
      )
      # shellcheck disable=SC2016
      declare -A pending=(
        [service]='(((.settings.service // "") + " " + (.settings.server // "")) | m) and ((.settings.key // "") == "")'
        [multistream]='[(.profiles // [])[] | select(.name == $p)] | (. == [] or (.[0].outputs // [] | pending))'
        [vertical]='(.canvas // []) != [] and (.canvas[0].stream_outputs // [] | pending)'
      )

      # Non-blank check that never turns the key into a shell word (xtrace-safe).
      hasKey() { jq -Rse 'test("\\S")' "$1" >/dev/null 2>&1; }
      # The boot-time Proton fetch (modules/secrets) is over once its self-heal
      # unit has finished — waiting any longer cannot produce a key.
      fetchDone() {
        case "$(systemctl show -P ActiveState proton-secrets-selfheal.service 2>/dev/null)" in
          active | failed) return 0 ;;
          *) return 1 ;;
        esac
      }
      deadline=$(( $(date +%s) + wait ))
      rc=0
      # A killed run must not leave a keyed temp file behind (*.tmp is also
      # excluded by obs-config-snapshot, which covers SIGKILL / power loss).
      tmp=""
      trap 'rm -f -- "$tmp"' EXIT

      while IFS= read -r t; do
        label=$(jq -r .label <<<"$t"); target=$(jq -r .target <<<"$t")
        keyFile=$(jq -r .keyFile <<<"$t"); match=$(jq -r .match <<<"$t")
        create=$(jq -c .create <<<"$t"); profile=$(jq -r '.profile // ""' <<<"$t")

        case "$target" in
          service) f="$obsDir/basic/profiles/$profile/service.json" ;;
          multistream) f="$obsDir/plugin_config/aitum-multistream/config.json" ;;
          vertical) f="$obsDir/plugin_config/vertical-canvas/config.json" ;;
        esac
        # Aitum Multistream keys its outputs by the profile's display name.
        pname=""
        if [ "$target" = multistream ]; then
          pname=$(awk '/^\[/ { s = $0 } s == "[General]" && /^Name=/ { sub(/^Name=/, ""); print; exit }' \
            "$obsDir/basic/profiles/$profile/basic.ini" 2>/dev/null || true)
          if [ -z "$pname" ]; then
            echo "obs-stream-keys: $label: profile '$profile' has no basic.ini [General] Name — skipped" >&2
            continue
          fi
        fi
        # Only multistream may start from nothing; the others need OBS's own file.
        if [ ! -e "$f" ] && [ "$target" != multistream ]; then
          echo "obs-stream-keys: $label: $f does not exist yet — skipped" >&2
          continue
        fi
        doc() { if [ -e "$f" ]; then cat "$f"; else echo '{}'; fi; }
        jqargs=(--arg m "$match" --arg p "$pname" --arg t "$target" --argjson c "$create")

        # Wait only for a key that is still being FETCHED (file not readable
        # yet); a fetched-but-blank field will not change, so it never waits.
        if [ ! -r "$keyFile" ] && [ "$wait" -gt 0 ] \
          && doc | jq -e "''${jqargs[@]}" --arg k "" "$common ''${pending[$target]}" >/dev/null 2>&1; then
          echo "obs-stream-keys: $label: no key injected yet; waiting up to $wait s for $keyFile..." >&2
          while [ ! -r "$keyFile" ] && [ "$(date +%s)" -lt "$deadline" ] && ! fetchDone; do sleep 1; done
        fi
        if [ ! -r "$keyFile" ]; then
          echo "obs-stream-keys: $label: $keyFile missing (secrets not fetched?) — skipped" >&2
          continue
        elif ! hasKey "$keyFile"; then
          echo "obs-stream-keys: $label: $keyFile is blank — check that Proton Pass field — skipped" >&2
          continue
        fi
        # Another launcher may have started OBS while this one waited.
        if obsRunning; then
          echo "obs-stream-keys: OBS started meanwhile — not touching its config" >&2
          exit 1
        fi

        mkdir -p "$(dirname "$f")"
        tmp=$(mktemp --suffix=.tmp "$f.XXXXXX")
        if doc | jq "''${jqargs[@]}" --rawfile k "$keyFile" "$common ''${inject[$target]}" > "$tmp"; then
          if [ -e "$f" ] && cmp -s "$tmp" "$f"; then
            rm -f "$tmp"
          else
            if [ -e "$f" ]; then chmod --reference="$f" "$tmp"; fi
            mv -f "$tmp" "$f"
            echo "obs-stream-keys: $label: key written to $f" >&2
          fi
        else
          rm -f "$tmp"
          echo "obs-stream-keys: $label: could not inject into $f (see jq error above)" >&2
          rc=1
        fi
      done < <(jq -c '.[]' "$spec")
      exit "$rc"
    '';
  };
in {
  options.calamoose.obs.streamKeys = lib.mkOption {
    default = {};
    description = ''
      Stream keys to inject into the OBS config of whoever runs
      `obs-stream-keys` (obs-kiosk runs it before every launch). Each entry
      reads one secret file and writes it into one place OBS keeps keys; see the
      notes above `streamKeysCfg` in this file. Empty = no injector installed.
    '';
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        target = lib.mkOption {
          type = lib.types.enum ["service" "multistream" "vertical"];
          description = ''
            `service`: the profile's main output (service.json; only when its
            service/server matches `match`). `multistream`: Aitum Multistream
            outputs of the profile. `vertical`: Aitum Vertical stream outputs
            (global across profiles).
          '';
        };
        keyFile = lib.mkOption {
          type = lib.types.str;
          description = "Runtime path of the secret holding the key (e.g. a calamoose.secrets.<name>.path readable by the OBS user).";
        };
        profile = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "The_Company_Inc";
          description = "OBS profile DIRECTORY under basic/profiles (service + multistream targets).";
        };
        match = lib.mkOption {
          type = lib.types.str;
          example = "youtube.com";
          description = "Case-insensitive substring of the ingest server (or service name, for `service`) that selects the output(s) to key.";
        };
        create = lib.mkOption {
          type = lib.types.nullOr (lib.types.submodule {
            options = {
              name = lib.mkOption {type = lib.types.str;};
              server = lib.mkOption {type = lib.types.str;};
            };
          });
          default = null;
          description = ''
            Output to add when none qualifies (multistream/vertical only; null =
            skip instead). Required for `vertical`, where `name` also IDENTIFIES
            the output to key: that list is global, so only the output with this
            name (or one already holding this exact key, which is renamed to it
            once) is touched.
          '';
        };
      };
    });
  };

  config = lib.mkMerge [
    {
      assertions =
        lib.mapAttrsToList (label: t: {
          assertion = t.target == "vertical" || t.profile != null;
          message = "calamoose.obs.streamKeys.${label}: target \"${t.target}\" needs `profile` (the basic/profiles directory name).";
        })
        streamKeysCfg
        ++ lib.mapAttrsToList (label: t: {
          assertion = t.target != "service" || t.create == null;
          message = "calamoose.obs.streamKeys.${label}: `create` is not supported for target \"service\" (the main output always exists).";
        })
        streamKeysCfg
        ++ lib.mapAttrsToList (label: t: {
          assertion = t.target != "vertical" || t.create != null;
          message = "calamoose.obs.streamKeys.${label}: target \"vertical\" needs `create` — its output is identified by create.name (the list is shared across profiles).";
        })
        streamKeysCfg;
    }
    (lib.mkIf (streamKeysCfg != {}) {
      environment.systemPackages = [obsStreamKeys];
    })
    {
      calamoose.modules."obs-studio".betaAware = true;

      hardware.decklink.enable = true;

      # v4l2loopback for virtual camera
      boot.extraModulePackages = with config.boot.kernelPackages; [
        v4l2loopback
      ];
      boot.kernelModules = ["v4l2loopback"];
      boot.extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
      '';

      # OBS with decklink support enabled
      programs.obs-studio = {
        enable = true;
        enableVirtualCamera = true;
        package = let
          baseObs = obsPkgs.obs-studio.override {
            decklinkSupport = true;
            cudaSupport = true;
          };
        in
          # NVIDIA's EGL explicit-sync path (wp_linux_drm_syncobj) commits a
          # wl_surface with no acquire point set, which Hyprland/niri reject with
          # a fatal Wayland protocol error — crashing OBS when a projector opens
          # (and on capture-source teardown). Disabling explicit sync for OBS only
          # is the upstream-attested fix (obsproject/obs-studio#11022, #12007).
          # Vendor-agnostic and OBS-scoped, so it's safe across devbox (Hyprland,
          # plain obs) and broadcast (the obs-kiosk PRIME wrapper execs finalPackage).
          obsPkgs.symlinkJoin {
            name = "obs-studio-nosync";
            paths = [baseObs];
            nativeBuildInputs = [obsPkgs.makeWrapper];
            postBuild = ''
              wrapProgram $out/bin/obs --set __NV_DISABLE_EXPLICIT_SYNC 1
            '';
          };
        plugins = with obsPkgs.obs-studio-plugins; [
          wlrobs
          obs-aitum-multistream
          obs-backgroundremoval
          obs-pipewire-audio-capture
          obs-vertical-canvas
          obs-move-transition
          obs-source-record
          droidcam-obs
        ];
      };

      # DeckLink udev rules — deliberately the MAIN-pin `pkgs`, never obsPkgs.
      # hardware.decklink.enable does NOT install udev rules (it only ships the
      # DesktopVideoHelper systemd unit + the kernel driver, both from the main
      # pin), so this line is load-bearing — and Blackmagic strictly couples the
      # desktopvideo userspace to the driver version, so its rules must come from
      # the same channel as the driver (main 16.0 vs beta 16.3 at the time this
      # was split).
      services.udev.packages = [pkgs.blackmagic-desktop-video];

      # Open SRT port for camera streaming
      networking.firewall.allowedTCPPorts = [9998];
      networking.firewall.allowedUDPPorts = [9998];
    }
  ];
}
