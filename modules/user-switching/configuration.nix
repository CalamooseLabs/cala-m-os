{
  lib,
  pkgs,
  config,
  cala-m-os,
  ...
}: let
  cfg = config.userSwitching;
  hubUser = cala-m-os.globals.defaultUser;

  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  jq = "${pkgs.jq}/bin/jq";

  # Shared hyprpaper loader used by both change-user and exit-user.
  # Handles both absolute paths and paths beginning with ~.
  loadHyprpaper = targetHome: ''
    _load_hyprpaper() {
      local conf="$1"
      local home="$2"
      [ -f "$conf" ] || return 0
      ${hyprctl} hyprpaper unload all 2>/dev/null || true
      while IFS= read -r _L; do
        _L="''${_L#"''${_L%%[![:space:]]*}"}"
        case "$_L" in
          "preload ="*)
            _V="''${_L#preload = }"
            _V="''${_V/#\~/$home}"
            ${hyprctl} hyprpaper preload "$_V" 2>/dev/null || true
            ;;
          "wallpaper ="*)
            _V="''${_L#wallpaper = }"
            _MONITOR="''${_V%%,*}"
            _PATH="''${_V#*,}"
            _PATH="''${_PATH/#\~/$home}"
            ${hyprctl} hyprpaper wallpaper "$_MONITOR,$_PATH" 2>/dev/null || true
            ;;
        esac
      done < "$conf"
    }
    _load_hyprpaper ${targetHome} ${targetHome}
  '';

  # Full environment for the active persona. Expects $TARGET to be set.
  # useUserPackages installs each user's apps + .desktop files into
  # /etc/profiles/per-user/<user>, NOT into their home, so HOME/XDG_*_HOME
  # alone leave rofi drun showing hub's apps. XDG_DATA_DIRS and PATH must
  # point at the persona's per-user profile for drun to list and launch them.
  personaEnv = ''
    export HOME="/home/$TARGET"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_DATA_DIRS="/etc/profiles/per-user/$TARGET/share:''${XDG_DATA_DIRS:-/run/current-system/sw/share}"
    export PATH="/etc/profiles/per-user/$TARGET/bin:$PATH"
  '';

  change-user = pkgs.writeShellScriptBin "change-user" ''
    set -eu
    STATE="/run/user/$(id -u)/hub-switch"
    HUB_HOME="/home/${hubUser}"

    if [ -z "''${1:-}" ]; then
      echo "Usage: change-user <user>"
      exit 1
    fi
    TARGET="$1"

    if [ -f "$STATE" ]; then
      echo "Already switched to '$(head -1 "$STATE")'. Run exit-user first."
      exit 1
    fi
    if ! id "$TARGET" &>/dev/null; then
      echo "Error: user '$TARGET' not found."
      exit 1
    fi

    TARGET_HOME="/home/$TARGET"

    # Snapshot current Hyprland window addresses so exit-user knows what to close
    PREV_ADDRS=$(${hyprctl} clients -j 2>/dev/null | ${jq} -r '.[].address' | tr '\n' ' ' || true)

    mkdir -p "$(dirname "$STATE")"
    printf '%s\nfull\n%s\n' "$TARGET" "$PREV_ADDRS" > "$STATE"

    # --- Wallpaper ---
    ${loadHyprpaper ''"$TARGET_HOME"''}

    # --- Waybar ---
    pkill -x waybar 2>/dev/null || true
    sleep 0.3
    (
      ${personaEnv}
      export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}"
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      waybar &
      disown $!
    )

    echo "Switched to '$TARGET' (full). Run exit-user to return to ${hubUser}."
  '';

  swap-user = pkgs.writeShellScriptBin "swap-user" ''
    set -eu
    STATE="/run/user/$(id -u)/hub-switch"

    if [ -z "''${1:-}" ]; then
      echo "Usage: swap-user <user>"
      exit 1
    fi
    TARGET="$1"

    if [ -f "$STATE" ]; then
      echo "Already switched to '$(head -1 "$STATE")'. Run exit-user first."
      exit 1
    fi
    if ! id "$TARGET" &>/dev/null; then
      echo "Error: user '$TARGET' not found."
      exit 1
    fi

    mkdir -p "$(dirname "$STATE")"
    printf '%s\npartial\n' "$TARGET" > "$STATE"

    echo "Swapped to '$TARGET' (partial). New apps use /home/$TARGET. Run exit-user to revert."
  '';

  exit-user = pkgs.writeShellScriptBin "exit-user" ''
    set -eu
    STATE="/run/user/$(id -u)/hub-switch"
    HUB_HOME="/home/${hubUser}"

    if [ ! -f "$STATE" ]; then
      echo "Not currently switched to any user."
      exit 0
    fi

    TARGET=$(sed -n '1p' "$STATE")
    MODE=$(sed -n '2p' "$STATE")

    if [ "$MODE" = "full" ]; then
      PREV_ADDRS=$(sed -n '3p' "$STATE")

      # Close every Hyprland window that wasn't open before the switch
      CURR_ADDRS=$(${hyprctl} clients -j 2>/dev/null | ${jq} -r '.[].address' || true)
      for ADDR in $CURR_ADDRS; do
        if ! echo " $PREV_ADDRS " | grep -qw "$ADDR"; then
          ${hyprctl} dispatch closewindow "address:$ADDR" 2>/dev/null || true
        fi
      done
      sleep 0.5

      # Restore hub's wallpaper
      ${loadHyprpaper ''"$HUB_HOME"''}

      # Restore hub's waybar
      pkill -x waybar 2>/dev/null || true
      sleep 0.3
      WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}" \
      XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
      waybar &
      disown $!
    fi

    rm -f "$STATE"
    echo "Returned to ${hubUser}."
  '';

  # Waybar polls this — only emits output during a full change-user switch,
  # so waybar stays visually unchanged during a partial swap-user.
  persona-status = pkgs.writeShellScriptBin "persona-status" ''
    STATE="/run/user/$(id -u)/hub-switch"
    if [ -f "$STATE" ]; then
      MODE=$(sed -n '2p' "$STATE")
      if [ "$MODE" = "full" ]; then
        TARGET=$(sed -n '1p' "$STATE")
        printf '[%s]' "$TARGET"
      fi
    fi
  '';

  # Rofi launcher that transparently injects the active persona's environment
  rofi-persona = pkgs.writeShellScriptBin "rofi-persona" ''
    STATE="/run/user/$(id -u)/hub-switch"
    if [ -f "$STATE" ]; then
      TARGET=$(sed -n '1p' "$STATE")
      ${personaEnv}
      exec rofi -show drun
    else
      exec rofi -show drun
    fi
  '';
in {
  options.userSwitching = {
    enable = lib.mkEnableOption "hub user switching (change-user / swap-user / exit-user)";

    switchableUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Users that hub can switch to via change-user or swap-user.";
    };
  };

  config = lib.mkMerge [
    # rofi-persona and persona-status are always installed so the hyprland module
    # can use rofi-persona unconditionally — it transparently falls back to plain
    # rofi when no switch is active.
    {
      environment.systemPackages = [rofi-persona persona-status];
    }

    (lib.mkIf cfg.enable {
      # Shared group — hub and all personas can read/write each other's home dirs
      users.groups.personas = {};

      users.users = lib.mkMerge [
        {"${hubUser}".extraGroups = ["personas"];}
        (lib.genAttrs cfg.switchableUsers (_: {
          extraGroups = ["personas"];
          homeMode = "770";
        }))
      ];

      environment.systemPackages = [
        exit-user
        pkgs.jq
      ];

      home-manager.users.${hubUser}.home.packages = [
        change-user
        swap-user
        rofi-persona
      ];
    })
  ];
}
