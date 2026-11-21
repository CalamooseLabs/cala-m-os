# mailroom — the stream relay with a real OBS on the server. MediaMTX takes the
# feeds in, an OBS that mailroom starts and drives composes them, and the
# program goes out to Twitch and YouTube; mailroomd switches scenes on the
# feed's bitrate and serves the dashboard. It IS the production on a host that
# enrols it (broadcast, streamer profile): there is no desktop OBS beside it.
# Upstream is the reference for everything below: its README, and docs/GPU.md
# for a host with an NVIDIA card.
#
# Nobody sits at the box. It is run from other devices on the LAN:
#
#     http://<host>:8740/     the dashboard: go live, rehearse, end, the scenes
#                             and their layout editor, the destinations, the
#                             OBS desktop in the browser, the GPU card. Log in
#                             with any user name and the token as the password.
#     ws://<host>:4455        obs-websocket for remote-control apps (Moblin,
#                             Stream Deck, Companion), through mailroom's
#                             gateway; the password is on the dashboard
#                             (Setup > Remote control)
#     sudo mailroom-ctl ...   over SSH: connect | status | live | stop | scene
#
# ── How a feed gets in ──────────────────────────────────────────────────────
# Every ingest is a MediaMTX path with a user (its own name) and a password:
#
#     srt://<host>:8890?streamid=publish:<ingest>:<ingest>:<password>&pkt_size=1316
#     rtmp://<host>:1935/<ingest>?user=<ingest>&pass=<password>
#
# `sudo mailroom-ctl connect` prints both for every ingest with the real
# passwords, next to the dashboard's address and token. "live" is the MAIN
# ingest (the phone, or an IRL encoder): its bitrate is what switches between
# the scenes Ingest, Ingest Low-bitrate and Ingest Offline. A host names more
# ingests in calamoose.mailroom.extraIngests. OBS gets each one as a media
# source under the ingest's name (hidden, in the Ingest scene); none of them
# drives the switching and none gets a scene by itself, so a show made from one
# is a scene you build once: Open OBS desktop, add a scene, add the existing
# source to it (and the Overlay sources wanted), then take that scene on the
# dashboard. Taking any scene but the three Ingest ones pauses the switching
# until Auto.
#
# ── A stream day ────────────────────────────────────────────────────────────
#   1. Start the encoder. The dashboard's Live view shows the feed's bitrate.
#   2. "Before you go live" lists what needs a look (the feed, OBS, each
#      destination's key, the GPU). Rehearse runs the whole show with nothing
#      public — Twitch receives it as a bandwidth test, every other destination
#      is skipped — and ends by itself after 30 minutes.
#   3. Go live. From a rehearsal the same button (after a question) makes it
#      the show.
#   4. Scenes are one tap: BRB, Starting soon, Ending, Privacy, Auto.
#   5. End stream.
# After a reboot nothing is on the air, records or stays armed by itself
# (output.resumeAfterReboot below); the show starts when a person says so.
#
# ── Secrets made on the box ─────────────────────────────────────────────────
# The ingest passwords and the dashboard token are in no vault:
# mailroom-secrets.service writes them once, before the mailroom units start,
# into /var/lib/mailroom-secrets (root, 0700), and they stay as they are across
# rebuilds and reboots:
#
#     api-token         48 lower-case letters and digits (mailroomd wants >= 16)
#     ingest-<name>     32 of the same (mailroom-auth wants 8-128 of the set
#                       MediaMTX takes; these also survive an RTMP URL)
#
# The mailroom units read them through LoadCredential= when they start, and a
# unit whose file is not there yet just retries (none has a start limit). To
# replace one, off air — the encoder or the browser needs the new value:
#
#     sudo rm /var/lib/mailroom-secrets/ingest-live
#     sudo systemctl restart mailroom-secrets mailroom-auth    # an ingest password
#     sudo systemctl restart mailroom-secrets mailroomd        # the token
#
# ── The other services on the box ───────────────────────────────────────────
# Wired here when their modules are enrolled next to this one:
#   multichat   is told when the show goes public and when it ends
#               (integrations.webhooks, over loopback), and its chat, alerts
#               and giveaway pages are overlays;
#   chat-cards  its card overlay;
#   cobblemon-overlay   the toasts, badge and graveyard pages.
# See "Overlays" below for where each one sits and how to show a hidden one.
#
# ── Ports (the defaults, as evaluated on broadcast) ─────────────────────────
#   open in the firewall   8890/udp SRT ingest, 1935/tcp RTMP ingest,
#                          8740/tcp dashboard + API, 4455/tcp obs-websocket
#                          gateway
#   every interface, NOT opened   4460/tcp OBS's own obs-websocket (it cannot
#                          bind loopback; only mailroomd and its validation
#                          kit talk to it)
#   loopback only          4461 Twitch relay, 9996 auth hook, 9997 MediaMTX API,
#                          9998 MediaMTX metrics, 8888 HLS preview, and 9995
#                          MediaMTX playback with ISO recording
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.services.mailroom;
  hostCfg = config.calamoose.mailroom;

  # What is generated on the box (mailroom-secrets.service, below).
  ingestPasswordFile = name: "${hostCfg.secretsDir}/ingest-${name}";
  apiTokenFile = "${hostCfg.secretsDir}/api-token";
  generatedIngests = ["live"] ++ hostCfg.extraIngests;

  # The sibling services, when their modules are enrolled on this host too.
  # `config.services ? x` asks whether the option exists at all: a profile that
  # enrols mailroom without them must still evaluate.
  multichat = config.services.multichat;
  hasMultichat = config.services ? multichat && multichat.enable;
  chatCards = config.services.chat-cards;
  hasChatCards = config.services ? chat-cards && chatCards.enable;
  cobblemon = config.services.cobblemon-overlay;
  hasCobblemon = config.services ? cobblemon-overlay && cobblemon.enable;
  loopback = port: "http://127.0.0.1:${toString port}";

  # Overlay geometry is written down for a 1920x1080 canvas (half the 3840x2160
  # the studio scenes were laid out on) and scaled here to whatever canvas the
  # host configures, so a fresh layout lands in the same place on any 16:9
  # canvas. `at` rounds a position down, which keeps a box that touches the
  # right or bottom edge inside the canvas.
  canvasScale = cfg.obs.video.height / 1080.0;
  at = v: builtins.floor (v * canvasScale);
  overlay = {
    url,
    width,
    height,
    x ? 0,
    y ? 0,
    scale ? 1.0,
    scenes,
    visible ? true,
  }: {
    inherit url width height scenes visible;
    x = at x;
    y = at y;
    scale = scale * canvasScale;
  };
  # Every scene a viewer sits on while chatting: the three Ingest scenes, BRB
  # and Starting soon. (Privacy takes no overlay: mailroom refuses it.)
  chatScenes = ["live" "low" "offline" "brb" "starting"];
  # The full-frame layers that belong to a running show.
  showScenes = ["live" "low"];

  # ---- mailroom-secrets: the on-box passwords and the token -----------------
  secretsGenerator = pkgs.writeShellApplication {
    name = "mailroom-secrets";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      # mailroom-secrets [DIR]: write each secret that is not there yet.
      umask 077
      dir="''${1:-${hostCfg.secretsDir}}"
      mkdir -p "$dir"
      chmod 0700 "$dir"

      # gen <name> <length>: lower-case letters and digits, without a newline.
      # A file that holds something is left alone, so this never changes a
      # password an encoder already uses; an empty one (a power cut right
      # after its creation) is made again.
      gen() {
        local file="$dir/$1" value tmp
        if [ -s "$file" ]; then
          return 0
        fi
        value=$(head -c 4096 /dev/urandom | tr -dc 'a-z0-9')
        value=''${value:0:$2}
        if [ "''${#value}" -ne "$2" ]; then
          echo "mailroom-secrets: could not generate $file" >&2
          exit 1
        fi
        tmp=$(mktemp "$file.XXXXXX")
        printf '%s' "$value" >"$tmp"
        sync "$tmp"
        mv -f "$tmp" "$file"
        echo "mailroom-secrets: wrote $file ($2 characters)"
      }

      gen api-token 48
      ${lib.concatMapStrings (name: ''
          gen ${lib.escapeShellArg "ingest-${name}"} 32
        '')
        generatedIngests}
    '';
  };

  # ---- mailroom-ctl: the operator's shortcuts over SSH ----------------------
  ingestNames = lib.attrNames cfg.ingests;
  mainIngest =
    lib.findFirst (n: cfg.ingests.${n}.main) (lib.head ingestNames) ingestNames;
  # the main one first
  ctlIngests = [mainIngest] ++ lib.remove mainIngest ingestNames;
  # The gateway's password: a file of the host's, or the one mailroomd makes at
  # its first start.
  obsWsPasswordFile =
    if cfg.obsWebSocket.passwordFile != null
    then cfg.obsWebSocket.passwordFile
    else "${cfg.dataDir}/obs-websocket.password";
  publicHost =
    if cfg.publicHost == null
    then hostCfg.lanAddress
    else cfg.publicHost;

  ctl = pkgs.writeShellApplication {
    name = "mailroom-ctl";
    runtimeInputs = [pkgs.coreutils pkgs.curl pkgs.jq];
    text = ''
      usage() {
        cat <<'EOF'
      usage: mailroom-ctl <command>
        connect        what to paste into an encoder, a browser and a remote-control app
        status         on air or not, the scene, the feed, the destinations, the renderer
        live           go live; while a rehearsal runs, `live --confirm` makes it the show
        stop           end the show, or the rehearsal
        scene <name>   auto, live, low, offline, brb, starting, ending or privacy,
                       or any OBS scene by its name
      Everything here is also on the dashboard. It reads the secrets in
      ${hostCfg.secretsDir}, so it runs itself through sudo.
      EOF
      }

      die() {
        echo "mailroom-ctl: $*" >&2
        exit 1
      }

      case "''${1:-}" in
        connect | status | live | stop | scene) ;;
        "" | help | -h | --help)
          usage
          exit 0
          ;;
        *)
          usage >&2
          exit 2
          ;;
      esac

      if [ "$(id -u)" -ne 0 ]; then
        exec sudo -- "$0" "$@"
      fi

      base="http://127.0.0.1:${toString cfg.api.port}"
      token_file=${lib.escapeShellArg (toString cfg.api.tokenFile)}
      lan_host=${lib.escapeShellArg hostCfg.lanAddress}
      public_host=${lib.escapeShellArg publicHost}

      # secret <file>: its content the way mailroom reads a credential
      # (without line ends); fails when the file is missing or empty.
      secret() {
        local value
        [ -r "$1" ] || return 1
        value=$(tr -d '\r\n' <"$1")
        [ -n "$value" ] || return 1
        printf '%s' "$value"
      }

      # request <GET|POST> <path> [<json body>]: prints the answer's body; any
      # status but 200 ends the command with mailroomd's own words. The token
      # goes to curl on stdin, never on a command line.
      request() {
        local method="$1" path="$2" data="{}" token out code body
        if [ "$#" -ge 3 ]; then
          data="$3"
        fi
        token=$(secret "$token_file") || die "no dashboard token: $token_file is missing or empty (systemctl status mailroom-secrets)"
        local args=(--silent --show-error --noproxy '*' --max-time 20 --config - --write-out '\n%{http_code}' --request "$method")
        if [ "$method" = POST ]; then
          args+=(--header 'X-Mailroom: 1' --header 'Content-Type: application/json' --data "$data")
        fi
        out=$(printf 'header = "Authorization: Bearer %s"\n' "$token" | curl "''${args[@]}" "$base$path") ||
          die "mailroomd does not answer on $base (systemctl status mailroomd)"
        code=''${out##*$'\n'}
        body=''${out%$'\n'*}
        if [ "$code" != 200 ]; then
          die "$method $path: HTTP $code: $(jq -r '.error // .message // empty' <<<"$body" 2>/dev/null || true)"
        fi
        printf '%s\n' "$body"
      }

      show_ingest() { # <host> <name> <user> <password file> <label>
        local host="$1" name="$2" user="$3" file="$4" label="$5" pw
        echo
        echo "$label \"$name\""
        if [ -z "$file" ]; then
          echo "  (no password file: see the dashboard's Setup view)"
          return 0
        fi
        if ! pw=$(secret "$file"); then
          echo "  (no password yet: $file is missing or empty; systemctl status mailroom-secrets)"
          return 0
        fi
        ${lib.optionalString cfg.listeners.srt.enable ''
        echo "  SRT    srt://$host:${toString cfg.listeners.srt.port}?streamid=publish:$name:$user:$pw&pkt_size=1316"
      ''}
        ${lib.optionalString cfg.listeners.rtmp.enable ''
        echo "  RTMP   rtmp://$host:${toString cfg.listeners.rtmp.port}/$name?user=$user&pass=$pw"
        echo "         as server + stream key:  rtmp://$host:${toString cfg.listeners.rtmp.port}/$name   ?user=$user&pass=$pw"
      ''}
      }

      show_ingests() { # <host>
        ${lib.concatMapStrings (name: let
          i = cfg.ingests.${name};
        in ''
          show_ingest "$1" ${lib.escapeShellArgs [
            name
            i.user
            (
              if i.passwordFile == null
              then ""
              else i.passwordFile
            )
            (
              if name == mainIngest
              then "Main ingest"
              else "Ingest"
            )
          ]}
        '')
        ctlIngests}
      }

      connect() {
        local token pw
        echo "Mailroom on ${config.networking.hostName}: what to paste where"
        echo
        echo "Dashboard (any user name; the token is the password)"
        echo "  http://$lan_host:${toString cfg.api.port}/"
        if token=$(secret "$token_file"); then
          echo "  token  $token"
        else
          echo "  (no token yet: $token_file is missing or empty; systemctl status mailroom-secrets)"
        fi
        show_ingests "$lan_host"
        ${lib.optionalString cfg.obsWebSocket.enable ''
        echo
        echo "Remote control (obs-websocket: Moblin, Stream Deck, Companion)"
        echo "  ws://$lan_host:${toString cfg.obsWebSocket.port}"
        if pw=$(secret ${lib.escapeShellArg obsWsPasswordFile}); then
          echo "  password  $pw"
        else
          echo "  (mailroomd makes the password at its first start; it is also on the dashboard, Setup > Remote control)"
        fi
      ''}
        if [ "$public_host" != "$lan_host" ]; then
          echo
          echo "From outside the LAN (publicHost $public_host), the ingests:"
          show_ingests "$public_host"
        fi
      }

      status() {
        request GET /api/status | jq -r --arg main ${lib.escapeShellArg mainIngest} '
          "state         " + (
            if .rehearsal != null then "REHEARSAL (nothing public)"
            elif .streaming then "LIVE"
            else "off air" end)
            + (if .recording then ", recording" else "" end),
          "scene         " + (.sceneLabel // "?")
            + (if .switcherEnabled then "" else " (automatic switching is off)" end),
          "ingest        \(.ingest.name // $main) (main): " + (
            if .ingest.unknown then "unknown (MediaMTX does not answer)"
            elif .ingest.online then "online, \(.ingest.kbps | floor) kbps"
            else "offline" end),
          ((.iso.paths // [])[] | select(.kind == "ingest" and .path != $main) |
            "ingest        \(.path): " + (if .online then "online" else "offline" end)),
          ((.destinations.destinations // [])[] |
            "destination   \(.name): "
            + (if .enabled then "on" else "off" end)
            + ", " + (.state // "?")
            + (if .paused then ", " + .paused else "" end)
            + (if .arm == "perSession" then (if .armed then ", armed" else ", NOT armed" end) else "" end)
            + (if .configError then " [" + .configError + "]" elif .lastError then " [" + .lastError + "]" else "" end)),
          ((.outputs.list // [])[] |
            "output        \(.label // .name): \(.state // "?")"
            + (if .size then " " + .size + (if .fps then "@\(.fps)" else "" end) else "" end)
            + (if .encoder then " " + .encoder else "" end)),
          (if .outputs.modeText then "mode          " + .outputs.modeText else empty end),
          "rendering     " + (
            if .gpu.renderer == null then "no GPU configured"
            elif .gpu.renderer.mode == null then "OBS has not started yet"
            elif .gpu.renderer.hardware then (.gpu.renderer.label // .gpu.renderer.mode) + " (the card)"
            else (.gpu.renderer.label // .gpu.renderer.mode) + " (SOFTWARE"
              + (if .gpu.renderer.why then ": " + .gpu.renderer.why else "" end) + ")" end)
            + (if .outputs.encoder.plan then ", encoder plan " + .outputs.encoder.plan else "" end),
          ((.obs.overlays // []) as $o | if ($o | length) == 0 then empty else
            "overlays      \([$o[] | select(.pageAnswers == true)] | length) of \($o | length) pages answer"
            + ([$o[] | select(.error != null) | " [" + .name + ": " + .error + "]"] | join("")) end),
          ((.integrations.webhooks // [])[] |
            "webhook       \(.name): \(.delivered) delivered, \(.dropped) dropped"
            + (if .failing then ", FAILING [" + (.lastError // "?") + "]" else "" end)),
          ((.goLive.items // [])[] | select(.state == "fail" or .state == "warn") |
            "check         \(.state): \(.label): \(.detail)"),
          (if .mediamtx.up then empty else "MediaMTX does not answer (systemctl status mailroom-mediamtx)" end),
          ((.gpu.rebootNeeded // []) | if length > 0 then "REBOOT NEEDED: " + join("; ") else empty end),
          (if .outputs.updatePending then "OBS update pending (" + .outputs.updatePending + "): it applies itself off air" else empty end)
        '
      }

      command="$1"
      shift
      case "$command" in
        connect) connect ;;
        status) status ;;
        live)
          if [ "''${1:-}" = --confirm ]; then
            answer=$(request POST /api/stream/start '{"confirm": true}')
          else
            answer=$(request POST /api/stream/start)
          fi
          jq -r '.message' <<<"$answer"
          if [ "$(jq -r '.needsConfirm // false' <<<"$answer")" = true ]; then
            echo "Nothing changed. mailroom-ctl live --confirm makes the rehearsal the show; mailroom-ctl stop ends it."
            exit 3
          fi
          ;;
        stop)
          request POST /api/stream/stop | jq -r '.message'
          ;;
        scene)
          name="$*"
          [ -n "$name" ] || die "scene: which one? (auto, live, low, offline, brb, starting, ending, privacy, or an OBS scene's name)"
          case "$name" in
            auto | live | low | offline | brb | starting | ending | privacy)
              request POST /api/scene "$(jq -cn --arg scene "$name" '{scene: $scene}')" | jq -r '.message'
              ;;
            *)
              request POST /api/obs/scene "$(jq -cn --arg name "$name" '{name: $name}')" | jq -r '.message'
              ;;
          esac
          ;;
      esac
    '';
  };
in {
  imports = [
    inputs.mailroom.nixosModules.default
  ];

  options.calamoose.mailroom = {
    lanAddress = lib.mkOption {
      type = lib.types.str;
      example = "10.2.10.2";
      description = ''
        The address this host has on the LAN the stream is run from. The
        dashboard answers to it (api.allowedHosts), it is what
        `mailroom-ctl connect` prints, and until the host sets
        services.mailroom.publicHost it is also what the dashboard's connect
        panel and the guest invites show encoders.
      '';
    };
    extraIngests = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["battlestation"];
      description = ''
        Ingests besides "live" (the main one). Each becomes
        services.mailroom.ingests.<name> with a password generated on the box
        (secretsDir/ingest-<name>), and OBS gets it as a media source of that
        name. Names follow mailroom's rule: lower-case letters, digits and "-".
      '';
    };
    secretsDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/mailroom-secrets";
      description = ''
        Root-only directory (0700) for what mailroom-secrets.service generates
        once on the box: the dashboard token and the ingest passwords. On the
        persistent root, so a reboot and a rebuild keep them.
      '';
    };
  };

  config = {
    # The one package the main nixpkgs pin is too old for: mailroom's module
    # refuses a MediaMTX below 1.20 at evaluation (it would reject the
    # generated configuration and restart for ever), and the main pin has
    # 1.18. MediaMTX is a Go binary that only moves streams around; it touches
    # neither the GPU nor OBS, so taking it alone from nixpkgs-beta mixes
    # nothing that matters. Everything else of mailroom's stays on the main
    # pin, next to the NVIDIA driver. Drop this line once the main pin carries
    # MediaMTX 1.20 or newer (the assertion says so by passing without it).
    # Until then `nix flake update nixpkgs-beta` moves the ingest server: the
    # next switch restarts MediaMTX on the new version, every feed with it.
    # Take such a bump off air and look at `systemctl status
    # mailroom-mediamtx` afterwards: a MediaMTX that no longer accepts the
    # configuration mailroom generates restarts for ever, and there is no
    # ingest until the host is back on its previous generation.
    calamoose.beta.packages = ["mediamtx"];

    services.mailroom = {
      enable = true;

      # A real OBS on the server; what makes overlays, scenes of one's own and
      # the GPU path (hosts set obs.gpu.enable) possible.
      engine = "obs";

      # ---- Ingest --------------------------------------------------------
      # The listeners keep mailroom's defaults (SRT 8890/udp, RTMP 1935/tcp)
      # and are opened in the host firewall, like multichat's and chat-cards'
      # ports. Who reaches them from outside the LAN is the router's business.
      # SRTLA bonding (several modems into one feed) is not set up: it is
      # ingests.<name>.srtla = { enable = true; passphraseFile = ...; } on an
      # ingest of its own, with its UDP port (5000) opened by this same switch
      # (and a warning from mailroom about hiding /proc, which it explains).
      openFirewall = true;
      ingests =
        {
          live = {
            main = true;
            passwordFile = ingestPasswordFile "live";
          };
        }
        // lib.genAttrs hostCfg.extraIngests (name: {
          passwordFile = ingestPasswordFile name;
        });

      # What the connect panel and the guest invites print. A host that is
      # reached from outside under a public name sets publicHost itself.
      publicHost = lib.mkDefault hostCfg.lanAddress;

      # ---- The dashboard, from the LAN -------------------------------------
      # The box is headless, so the dashboard listens on every address and is
      # opened in the firewall. mailroom then insists on a token (asserted),
      # and answers only to the names it is told: publicHost, the loopback
      # names and these. A request under any other name gets 403 "host not
      # allowed" before any login — that is what keeps a DNS-rebinding page
      # away — so a host lists the names its LAN really uses for it.
      api = {
        listenAddress = "0.0.0.0";
        openFirewall = true;
        tokenFile = apiTokenFile;
        allowedHosts = [hostCfg.lanAddress config.networking.hostName];
      };

      # ---- Remote-control apps ----------------------------------------------
      # obs-websocket through mailroom's gateway, on its default port and every
      # address (the module's default), with the password mailroomd generates
      # and shows on the dashboard. The gateway is what a phone's Start button
      # talks to: in a rehearsal it makes the rehearsal the show.
      # mailroom's module warns about this at every evaluation, on purpose:
      # obs-websocket has no TLS, so the login and the session cross the
      # network in the clear. That is accepted here — the port is reachable
      # from the LAN only, behind the owner's router, the same trust the
      # dashboard's plain http already takes — and the warning is left visible
      # rather than silenced, so that it is read again the day the port is
      # forwarded or the box moves to a network that is not the owner's.
      obsWebSocket = {
        enable = true;
        openFirewall = true;
      };

      # ---- Never on the air by itself --------------------------------------
      # A box that is power-cycled with nobody watching must not go live,
      # record or stay armed when it comes back: after a reboot mailroomd
      # starts off the air and says in the activity log what it did not
      # resume. Restarts within one boot (a rebuild, a crash, Restart OBS)
      # still resume a running show; Privacy comes back on whatever this says.
      output = {
        autoStart = "manual";
        resumeAfterReboot = false;
      };

      # switcher.offlineTimeoutMinutes stays unset. It ends a show after the
      # MAIN ingest has been offline that long, whatever scene is on program:
      # a show made from another ingest (a game feed, with no phone connected)
      # would be stopped by it in mid-air. A host that only ever streams from
      # its main ingest sets it (mailroom's example uses 15).

      # ---- Recovery without SSH --------------------------------------------
      # "Reboot server" on the dashboard's GPU card: what a headless box has
      # in place of someone pressing the button, for a driver change or a GPU
      # that fell off the bus. mailroomd refuses it while anything is live or
      # recording and asks for a confirmation; the reboot itself is one root
      # unit, the only root unit polkit lets mailroomd start.
      recovery.allowReboot = true;

      # ---- multichat is told about the show -------------------------------
      # One POST per event to multichat's go-live hint, over loopback (which
      # is the only place multichat takes it from, and why there is no token).
      # A go-live, or a rehearsal made the show, is stream.started: multichat
      # stops waiting for its next YouTube poll and looks now. A rehearsal is
      # NOT a start: mailroom sends stream.state with streaming = false for
      # it, which multichat reads as "not live", so nothing public is looked
      # for or announced.
      # stateIntervalSeconds repeats the state every minute while the show is
      # on, and after it for as long as a delivery had been given up on. That
      # is the only thing that tells a multichat that was restarting at the
      # start that the show is on, and the only repair for a stream.stopped
      # it missed. multichat starts no second boost for a "still live" it
      # already knows.
      integrations = lib.mkIf hasMultichat {
        webhooks.multichat.url = "${loopback multichat.port}/api/live";
        stateIntervalSeconds = 60;
      };

      # ---- Overlays ----------------------------------------------------------
      # Pages of the other services on this box as browser sources "Overlay
      # <name>", which mailroom keeps in OBS: after a reinstall or a new scene
      # collection they are back without anyone opening OBS, and a page that
      # was not being served when OBS started is reloaded once it answers.
      #
      # url, width and height are mailroom's and are written back at every
      # start; change them here. x, y, scale and visible are where an item is
      # FIRST put, once per scene. After that the item is the operator's: move,
      # resize or hide it in the dashboard's layout editor (Scenes view) or in
      # OBS, and it stays that way — nothing here moves it again.
      #
      # The positions are the retired studio scenes' (see `at` above). OBS
      # keeps Mailroom's scenes in relative coordinates, so when a host raises
      # its canvas every item grows with it and keeps its place; the pages
      # themselves keep the pixel size given here, magnified. Sharper text
      # after such a raise is a bigger page here, at the cost of drawing it:
      # OBS draws every page on the CPU, GPU or not, which is why each has the
      # size of what it shows and the full-frame ones start hidden.
      #
      # "Hidden" layers are there to be switched on when wanted: dashboard >
      # Scenes, pick the scene, tick the item's eye. The Overlay sources can
      # also be added to a scene of one's own there (Add source).
      # Privacy takes no overlay and the vertical canvas's scenes get none;
      # mailroom refuses the first and leaves the second to the layout editor.
      obs.overlays = lib.mkMerge [
        (lib.mkIf hasMultichat {
          # The chat column on the left edge. direction=down is multichat's
          # default flow (newest at the bottom), spelled out as the studio
          # source had it.
          chat = overlay {
            url = "${loopback multichat.port}/overlay?direction=down";
            width = 350;
            height = 475;
            x = 0;
            y = 223;
            scenes = chatScenes;
          };
          # Follow, cheer, sub and raid pop-ups, top right. The theme is the
          # one modules/multichat makes active, by name, so the two cannot
          # drift apart.
          alerts = overlay {
            url = "${loopback multichat.port}/alerts?theme=${lib.escapeURL multichat.alerts.activeTheme}";
            width = 1000;
            height = 800;
            x = 1420;
            y = 0;
            scale = 0.5;
            scenes = chatScenes;
          };
          # The giveaway's case reel, full frame. The page is see-through and
          # empty between draws; it still costs a full-frame layer, so it is
          # switched on for a draw.
          giveaway = overlay {
            url = "${loopback multichat.port}/giveaway?overlay";
            width = 1920;
            height = 1080;
            scenes = showScenes;
            visible = false;
          };
        })
        (lib.mkIf hasChatCards {
          # chat-cards' pack-opening overlay, full frame (the page is made
          # for 1920x1080).
          cards = overlay {
            url = "${loopback chatCards.port}/overlay";
            width = 1920;
            height = 1080;
            scenes = showScenes;
            visible = false;
          };
        })
        (lib.mkIf hasCobblemon {
          # The Cobblemon Initiative's pages, where the studio's Gameplay
          # scene had them: capture and loss pop-ups top centre, the badge
          # count bottom right, the graveyard strip along the bottom. They
          # only mean something while the game runs, so all three wait hidden.
          cobblemon-toasts = overlay {
            url = "${loopback cobblemon.port}/overlay/toasts";
            width = 800;
            height = 600;
            x = 558;
            y = 0;
            scale = 1.44;
            scenes = showScenes;
            visible = false;
          };
          cobblemon-badges = overlay {
            url = "${loopback cobblemon.port}/overlay/badges";
            width = 250;
            height = 100;
            x = 1570;
            y = 820;
            scale = 1.4;
            scenes = showScenes;
            visible = false;
          };
          # The page anchors its whole scene to the bottom edge and leaves
          # everything above the skyline see-through. The studio source was
          # 600 px high with the top 381 cropped away; mailroom has no crop,
          # so the page is given the height of what it draws instead.
          cobblemon-graveyard = overlay {
            url = "${loopback cobblemon.port}/overlay/graveyard?tooltips=1";
            width = 1000;
            height = 220;
            x = 360;
            y = 736;
            scale = 1.56;
            scenes = showScenes;
            visible = false;
          };
        })
      ];

      # chat.twitch stays off: multichat owns chat on this box, and mailroom's
      # bot would need a long-lived chat token of its own (a new secret).
      # Nothing is lost with it. Every command upstream's guides give as chat
      # (!rehearse, !yv on, !obs gpu, ...) has its button on the dashboard,
      # and the Live view's command box runs any of them as typed. To have
      # the bot after all: chat.twitch = { enable = true; channels = [...];
      # nick = "<bot account>"; tokenFile = <an optional calamoose.secrets
      # entry with restartUnits = ["mailroomd.service"]>; }.
    };

    # Generated once, before the units that read them. A unit rather than an
    # activation snippet, so that its place in the boot order is written down
    # (before =) and a failed run is tried again.
    systemd.services.mailroom-secrets = {
      description = "Mailroom: the ingest passwords and the dashboard token, generated once";
      wantedBy = ["multi-user.target"];
      before = [
        "mailroom-auth.service"
        "mailroom-mediamtx.service"
        "mailroomd.service"
        "mailroom-gpu-check-quick.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = lib.getExe secretsGenerator;
        # A failure (a full disk) is tried again by itself; the units that
        # wait for a file retry on their own and start once it is there.
        Restart = "on-failure";
        RestartSec = 10;
        UMask = "0077";
        NoNewPrivileges = true;
        PrivateNetwork = true;
        ProtectHome = true;
      };
    };

    # On every login's PATH. mailroom's own validation kit (mailroom-gpu-check)
    # is put there by its module once a host sets obs.gpu.enable; tmux is for
    # running it: its off-air levels take minutes to hours, and upstream's
    # guide wants them inside tmux so a dropped SSH session does not end one.
    environment.systemPackages = [ctl pkgs.tmux];
  };
}
