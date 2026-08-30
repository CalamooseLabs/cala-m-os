{
  pkgs,
  osConfig,
  lib,
  config,
  ...
}: let
  switching = osConfig.userSwitching.enable or false;
  privacy = osConfig.cala.waybar.streamPrivacy.enable or false;
  cfg = config.cala.waybar;

  # Active-style base16 palette (see hosts/_core/options.nix → calamoose.style),
  # emitted as GTK @define-color rules. Both the main bar stylesheet AND the
  # standalone cap process (a separate waybar with no stylix prelude of its own)
  # prepend this so @baseNN resolves to the chosen style. calamooselabs resolves
  # to the same gruvbox hex the CSS used before, so its look is unchanged.
  scheme = osConfig.stylix.base16Scheme;
  palette =
    lib.concatMapStringsSep "\n"
    (n: "@define-color ${n} ${scheme.${n}};")
    ["base00" "base01" "base02" "base03" "base04" "base05" "base06" "base07" "base08" "base09" "base0A" "base0B" "base0C" "base0D" "base0E" "base0F"]
    + "\n";

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
    # Overlay, NOT top: while collapsed the main bar goes invisible but its
    # surface stays mapped on the "top" layer across the whole strip. On "top"
    # the cap stacks *under* it, so clicks on the handle hit the dead main bar
    # (only the keybind worked). Overlay sits above "top" -> the ❮ is clickable.
    layer = "overlay";
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
    ${palette}
    * {
      font-family: "MesloLGS NF";
      font-size: 15px;
      min-height: 0;
    }
    window#waybar.cap {
      background: transparent;
    }
    /* Identical to the bar's left end cap (#custom-collapse), just the arrow
       pointing the other way (❮ = pull the bar back out). */
    #custom-cap {
      background: alpha(@base00, 0.92);
      color: @base04;
      margin: 6px 0;
      padding: 4px 16px;
      border-radius: 18px 0 0 18px;
      transition: color 200ms ease;
    }
    #custom-cap:hover {
      color: @base0C;
    }
  '';

  # Appended to the main bar's stylesheet when collapse is enabled: the new
  # leftmost module becomes the rounded cap / collapse handle, and the music
  # capsule gives up its left rounding.
  collapseCss = ''

    /* collapse handle = the rounded left cap */
    #custom-collapse {
      background: alpha(@base00, 0.92);
      color: @base04;
      margin: 6px 0;
      padding: 4px 16px;
      border-radius: 18px 0 0 18px;
      transition: color 200ms ease;
    }
    #custom-collapse:hover {
      color: @base0C;
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

  # --- Stream-privacy wallpaper toggle -----------------------------------
  # A bar button that hides the personal desktop for streaming by swapping the
  # wallpaper to The Company, Inc. brand art AT RUNTIME (hyprctl hyprpaper), so
  # it can be flipped mid-stream with no rebuild. State is a file in
  # XDG_RUNTIME_DIR; the button glyph reflects it. The two wallpaper store paths
  # are baked in: `normalWp` is this host's active Stylix wallpaper (whatever the
  # calamoose.style resolves to), `privacyWp` is the brand art shared with the
  # thecompany style / hyprlock.
  normalWp = "${osConfig.stylix.image}";
  privacyWp = "${../../assets/thecompany-wallpaper.png}";

  privacyToggle = pkgs.writeShellApplication {
    name = "cala-stream-privacy-toggle";
    runtimeInputs = [pkgs.hyprland pkgs.procps];
    text = ''
      state="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/cala-stream-privacy"
      set_wallpaper() {
        # preload -> set active -> drop the now-unused previous image
        hyprctl hyprpaper preload "$1"    >/dev/null 2>&1 || true
        hyprctl hyprpaper wallpaper ",$1" >/dev/null 2>&1 || true
        hyprctl hyprpaper unload unused   >/dev/null 2>&1 || true
      }
      if [ -f "$state" ]; then
        set_wallpaper "${normalWp}"
        rm -f "$state"
      else
        set_wallpaper "${privacyWp}"
        : > "$state"
      fi
      # refresh the bar button immediately (custom/privacy listens on SIGRTMIN+8)
      pkill -RTMIN+8 -x waybar 2>/dev/null || true
    '';
  };

  # The two "text" values below hold real Nerd-Font PUA glyphs (eye-slash for
  # on/hidden, eye for off/visible). They render as icons but look like EMPTY
  # strings in most editors -- do NOT delete or "clean them up": this button
  # shipped with an empty text exactly once for that reason, and Waybar HIDES a
  # custom module whose text is empty, so the whole button silently vanished.
  # State colour is set in privacyCss; on = safe to stream, off = desktop shown.
  privacyStatus = pkgs.writeShellScript "waybar-stream-privacy" ''
    state="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/cala-stream-privacy"
    if [ -f "$state" ]; then
      printf '{"text":"","class":"on","tooltip":"Stream privacy ON (company wallpaper) — click to restore your desktop"}\n'
    else
      printf '{"text":"","class":"off","tooltip":"Stream privacy OFF — click to hide your desktop for streaming"}\n'
    fi
  '';

  # Appended to the main bar stylesheet only when the toggle is enabled: a plain
  # pill (style.css's shared body doesn't list this id) that lights green while
  # privacy is on = safe to stream.
  privacyCss = ''

    #custom-privacy {
      background: alpha(@base00, 0.92);
      margin: 6px 0;
      padding: 4px 11px;
      /* nudge just the eye glyph up a touch from the bar's shared 15px */
      font-size: 17px;
      transition: color 200ms ease;
    }
    #custom-privacy.off {
      color: @base04;
    }
    #custom-privacy.on {
      color: @base0B;
    }
    #custom-privacy:hover {
      color: @base0C;
    }
  '';
  # --- Quick-launch pills --------------------------------------------------
  # Host-defined launcher buttons (see the option below), rendered as one pill
  # per entry just left of the clock. Launches go through systemd-run so the
  # app escapes waybar.service's cgroup — on-click children are otherwise
  # killed whenever the bar restarts (which happens on every compositor
  # re-exec, since hyprland-session.target is stop/started then).
  quickLaunchModules = lib.listToAttrs (map (e: {
      name = "custom/ql-${e.id}";
      value =
        {
          format = e.glyph;
          on-click = "${pkgs.systemd}/bin/systemd-run --user --collect -- ${e.command}";
        }
        // (
          if e.tooltip != ""
          then {
            tooltip = true;
            tooltip-format = e.tooltip;
          }
          else {tooltip = false;}
        );
    })
    cfg.quickLaunch);

  # Same pill body as the shared block in style.css (that selector is an
  # explicit id list, so new ids get nothing for free); 17px matches the
  # privacy pill's glyph-size nudge.
  quickLaunchCss = lib.optionalString (cfg.quickLaunch != []) ''

    ${lib.concatMapStringsSep ", " (e: "#custom-ql-${e.id}") cfg.quickLaunch} {
      background: alpha(@base00, 0.92);
      margin: 6px 0;
      padding: 4px 11px;
      font-size: 17px;
      color: @base04;
      transition: color 200ms ease;
    }
    ${lib.concatMapStringsSep ", " (e: "#custom-ql-${e.id}:hover") cfg.quickLaunch} {
      color: @base0C;
    }
  '';
in {
  options.cala.waybar.collapse.enable =
    lib.mkEnableOption "the collapsible right-docked waybar — click the rounded cap to slide it to a stub; collapsing releases the top strip so Hyprland reclaims the vertical space"
    // {default = true;};

  options.cala.waybar.powerCommand = lib.mkOption {
    type = lib.types.str;
    default = "powermenu";
    description = ''
      Command the bar's power pill runs on click. The default expects the rofi
      module's powermenu on PATH; hosts without rofi point it elsewhere (the
      broadcast box uses obs-safe-poweroff so a click is a safe shutdown).
    '';
  };

  options.cala.waybar.quickLaunch = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        id = lib.mkOption {
          type = lib.types.strMatching "[a-z0-9-]+";
          description = "Slug for the module/CSS id (custom/ql-<id>).";
        };
        glyph = lib.mkOption {
          # nonEmptyStr: waybar HIDES a custom module whose text is empty, so a
          # lost glyph would make the button silently vanish (this bar shipped
          # that bug once with the privacy pill) — fail the eval instead.
          type = lib.types.nonEmptyStr;
          description = ''
            Nerd-Font glyph shown in the pill. PUA glyphs look EMPTY in most
            editors — don't "clean them up".
          '';
        };
        command = lib.mkOption {
          type = lib.types.str;
          description = "Command to launch (word-split; wrapped in systemd-run --user so it survives bar restarts).";
        };
        tooltip = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Hover text; empty disables the tooltip.";
        };
      };
    });
    default = [];
    description = ''
      Quick-launch buttons rendered as pills left of the clock — e.g. the
      broadcast box's relaunch-OBS / Companion / Multichat buttons.
    '';
  };

  config = {
    assertions = [
      {
        assertion = lib.allUnique (map (e: e.id) cfg.quickLaunch);
        message = "cala.waybar.quickLaunch: id values must be unique (duplicates would silently collapse to the first entry's command)";
      }
    ];

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

    home.packages =
      lib.optional cfg.collapse.enable toggleScript
      ++ lib.optional privacy privacyToggle;

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
              ++ lib.optional privacy "custom/privacy"
              ++ map (e: "custom/ql-${e.id}") cfg.quickLaunch
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
              # systemd-run for the same reason as the quick-launch pills: an
              # on-click child dies with the bar, and for a powerCommand like
              # obs-safe-poweroff a bar restart mid-wait would strand the box
              # with OBS stopped but no poweroff issued.
              on-click = "${pkgs.systemd}/bin/systemd-run --user --collect -- ${cfg.powerCommand}";
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
          // lib.optionalAttrs privacy {
            # Runs once at start, then re-reads on click (exec-on-event) and on
            # SIGRTMIN+8 (fired by the toggle) — no polling. Click swaps the
            # wallpaper and flips the glyph.
            "custom/privacy" = {
              exec = "${privacyStatus}";
              return-type = "json";
              interval = "once";
              signal = 8;
              tooltip = true;
              on-click = "${privacyToggle}/bin/cala-stream-privacy-toggle";
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
          }
          // quickLaunchModules;
      };

      style = palette + builtins.readFile ./style.css + lib.optionalString cfg.collapse.enable collapseCss + lib.optionalString privacy privacyCss + quickLaunchCss;
    };
  };
}
