{
  pkgs,
  osConfig,
  lib,
  config,
  ...
}: let
  switching = osConfig.userSwitching.enable or false;
  cfg = config.cala.waybar;

  # --- Collapse feature --------------------------------------------------
  # Two waybar instances: the home-manager-managed MAIN bar (which owns the
  # exclusive zone / reserved top strip) and a standalone non-exclusive CAP.
  # Collapsing hides the main bar via SIGUSR1 -> waybar's "invisible" mode sets
  # the layer-shell exclusive zone to 0, so Hyprland reclaims the vertical strip
  # and reflows windows up; expanding (SIGUSR2 -> "show") re-reserves it. The cap
  # is a separate PROCESS because SIGUSR is delivered per-process and a clickable
  # handle must stay alive while the main bar is hidden.
  toggleScript = pkgs.writeShellApplication {
    name = "cala-waybar-collapse";
    runtimeInputs = [pkgs.systemd pkgs.coreutils];
    text = ''
      # Deterministic toggle: explicit hide/show keyed off a state file, so the
      # bar's real visibility can never drift from what we think it is.
      state="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/cala-waybar-collapsed"
      if [ -f "$state" ]; then
        # collapsed -> expand: show the main bar (re-reserves the strip), hide the cap
        systemctl --user kill --signal=SIGUSR2 waybar.service     || true
        systemctl --user kill --signal=SIGUSR1 waybar-cap.service || true
        rm -f "$state"
      else
        # expanded -> collapse: hide the main bar (releases the strip), show the cap
        systemctl --user kill --signal=SIGUSR1 waybar.service     || true
        systemctl --user kill --signal=SIGUSR2 waybar-cap.service || true
        : > "$state"
      fi
    '';
  };

  # The cap's own config + style (a 2nd waybar process via -c/-s). Non-exclusive
  # so it never reserves space; starts hidden (expanded is the default state).
  capConfig = pkgs.writeText "waybar-cap-config.jsonc" (builtins.toJSON {
    name = "cap";
    layer = "top";
    position = "top";
    exclusive = false;
    passthrough = false;
    start_hidden = true;
    on-sigusr1 = "hide";
    on-sigusr2 = "show";
    modules-left = [];
    modules-center = [];
    modules-right = ["custom/cap"];
    "custom/cap" = {
      format = "❮";
      tooltip = false;
      on-click = "${toggleScript}/bin/cala-waybar-collapse";
    };
  });

  capStyle = pkgs.writeText "waybar-cap-style.css" ''
    * {
      font-family: "MesloLGS NF";
      font-size: 15px;
      min-height: 0;
    }
    window#waybar.cap {
      background: transparent;
    }
    #custom-cap {
      background: rgba(30, 33, 35, 0.92);
      color: #c9d05c;
      margin: 6px 0;
      padding: 4px 16px;
      border-radius: 18px 0 0 18px;
    }
    #custom-cap:hover {
      color: #eeeeee;
    }
  '';

  # Appended to the main bar's stylesheet when collapse is enabled: the new
  # leftmost module becomes the rounded cap / collapse handle, and the music
  # capsule gives up its left rounding.
  collapseCss = ''

    /* collapse handle = the rounded left cap */
    #custom-collapse {
      background: rgba(30, 33, 35, 0.92);
      color: #b8b8b8;
      margin: 6px 0;
      padding: 4px 16px;
      border-radius: 18px 0 0 18px;
      transition: color 200ms ease;
    }
    #custom-collapse:hover {
      color: #73cef4;
    }
    #custom-music {
      border-radius: 0;
    }
  '';

  # Now-playing source for the sliding music capsule. Emits Waybar JSON with a
  # play-state class ("playing"/"stopped") so the stylesheet can animate the
  # reveal. Title is markup-escaped (also makes it JSON-safe: " becomes &quot;).
  musicScript = pkgs.writeShellScript "waybar-music" ''
    status=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null || true)
    if [ "$status" = "Playing" ]; then
      title=$(${pkgs.playerctl}/bin/playerctl metadata --format '{{markup_escape(title)}}' 2>/dev/null)
      printf '{"text":"  %s","class":"playing"}\n' "$title"
    else
      printf '{"text":" ","class":"stopped"}\n'
    fi
  '';
in {
  options.cala.waybar.collapse.enable =
    lib.mkEnableOption "the collapsible right-docked waybar — click the rounded cap to slide it to a stub; collapsing releases the top strip so Hyprland reclaims the vertical space"
    // {default = true;};

  config = {
    # Let it try to start a few more times
    systemd.user.services.waybar = {
      Unit.StartLimitBurst = 30;
    };

    # Standalone always-present cap (2nd waybar process; home-manager manages
    # only one). Non-exclusive: reserves no space, floats the rounded expand
    # handle at the top-right while collapsed. Shown/hidden via SIGUSR.
    systemd.user.services.waybar-cap = lib.mkIf cfg.collapse.enable {
      Unit = {
        Description = "Waybar collapse cap (standalone, non-exclusive)";
        PartOf = ["hyprland-session.target"];
        After = ["hyprland-session.target"];
      };
      Service = {
        ExecStart = "${config.programs.waybar.package}/bin/waybar -c ${capConfig} -s ${capStyle}";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    home.packages = lib.optional cfg.collapse.enable toggleScript;

    programs.waybar = {
      enable = true;

      systemd = {
        enable = true;
        targets = ["hyprland-session.target"];
      };

      settings = {
        mainBar =
          {
            layer = "top";
            position = "top";
            # Right-docked bar: flush against the right screen edge (flat right
            # end), rounded left cap. The music capsule is the leftmost element
            # and slides out to the left while something is playing, then slides
            # back to a slim rounded cap when idle (animated in style.css).
            modules-left = [];
            modules-center = [];
            modules-right =
              lib.optional cfg.collapse.enable "custom/collapse"
              ++ ["custom/music"]
              ++ lib.optional switching "custom/persona"
              ++ ["clock" "pulseaudio" "network" "backlight" "battery" "custom/power"];

            "custom/music" = {
              format = "{}";
              return-type = "json";
              interval = 1;
              tooltip = false;
              exec = "${musicScript}";
              max-length = 40;
            };

            clock = {
              tooltip-format = ''
                <big>{:%Y %B}</big>
                <tt><small>{calendar}</small></tt>'';
              format-alt = " {:%a. %m %d %Y}";
              format = " {:%I:%M %p}";
            };

            network = {
              format-wifi = "";
              format-disconnected = "󰤮";
              format-ethernet = "";
              on-click = "ghostty -e nmtui"; # TODO: Change this to using terminal variable
              tootip = false;
            };

            backlight = {
              device = "intel_backlight";
              format = "{icon}";
              format-icons = ["" "" "" "" "" "" "" "" ""];
              format-alt = "{icon} {percent}%";
            };

            battery = {
              states = {
                warning = 30;
                critical = 15;
              };
              format = "{icon}";
              format-charging = "";
              format-plugged = "";
              format-alt = "{icon} {capacity}%";
              format-icons = ["" "" "" "" "" "" "" "" "" "" "" ""];
            };

            pulseaudio = {
              format = "{icon} {volume}%";
              format-muted = "";
              format-icons = ["" "" " "];
              on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
            };

            "custom/power" = {
              tooltip = false;
              on-click = "powermenu";
              format = "襤";
            };
          }
          // lib.optionalAttrs switching {
            "custom/persona" = {
              exec = "persona-status";
              interval = 2;
              format = "{}";
              tooltip = false;
              on-click = "exit-user";
              return-type = "";
            };
          }
          // lib.optionalAttrs cfg.collapse.enable {
            # SIGUSR1 -> hide (invisible mode -> exclusive zone 0 -> Hyprland
            # reclaims the strip); SIGUSR2 -> show. Driven by the toggle script.
            on-sigusr1 = "hide";
            on-sigusr2 = "show";
            start_hidden = false;
            # the rounded left cap = the collapse handle
            "custom/collapse" = {
              format = "❯";
              tooltip = false;
              on-click = "${toggleScript}/bin/cala-waybar-collapse";
            };
          };
      };

      style = builtins.readFile ./style.css + lib.optionalString cfg.collapse.enable collapseCss;
    };
  };
}
