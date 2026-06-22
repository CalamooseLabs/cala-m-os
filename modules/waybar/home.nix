{
  pkgs,
  osConfig,
  lib,
  ...
}: let
  switching = osConfig.userSwitching.enable or false;

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
  # Let it try to start a few more times
  systemd.user.services.waybar = {
    Unit.StartLimitBurst = 30;
  };

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
            ["custom/music"]
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
        };
    };

    style = builtins.readFile ./style.css;
  };
}
