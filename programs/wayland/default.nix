{ pkgs, inputs, ... }:

{
  # Let it try to start a few more times
  systemd.user.services.waybar = {
    Unit.StartLimitBurst = 30;
  };
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target"; # NOTE = hyprland/default.nix stops graphical-session.target and starts hyprland-sessionl.target
    };

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        modules-left = ["wlr/workspaces"];
        modules-center = ["custom/music"];
        modules-right = ["pulseaudio" "network" "backlight" "battery" "clock" "tray" "custom/power"];

        "wlr/workspaces" = {
            disable-scroll = true;
            sort-by-name = true;
            format = "{icon}";
            format-icons = {default = "";};
        };

        tray = {
            icon-size = 21;
            spacing = 10;
        };

        "custom/music" = {
            format = "  {}";
            escape = true;
            interval = 5;
            tooltip = false;
            exec = "${pkgs.playerctl}/bin/playerctl metadata --format '{{ title }}'";
            max-length = 50;
        };

        clock = {
            tooltip-format = ''
                <big>{:%Y %B}</big>
                <tt><small>{calendar}</small></tt>'';
            format-alt = " {:%d/%m/%Y}";
            format = " {:%H:%M}";
        };

        network = {
            format-wifi = "";
            format-disconnected = "";
            format-ethernet = "";
            format-alt = "  {signalStrength}%";
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
            on-click = "pavucontrol";
        };

        "custom/power" = {
            tooltip = false;
            on-click = "bash ~/.config/rofi/scripts/powermenu.sh";
            format = "襤";
        };
      };
    };

    style = ''
      * {
        font-family: FantasqueSansMono Nerd Font;
        font-size: 17px;
        min-height: 0;
      }

      #waybar {
        background: transparent;
        color: @text;
        margin: 5px 5px;
      }

      #workspaces {
        border-radius: 1rem;
        margin: 5px 0px;
        background-color: @surface0;
        margin-left: 1rem;
      }

      #workspaces button {
        color: @lavender;
        border-radius: 1rem;
        padding: 0.5rem;
      }

      #workspaces button.active {
        color: @sky;
        border-radius: 1rem;
      }

      #workspaces button:hover {
        color: @sapphire;
        border-radius: 1rem;
      }

      #custom-music,
      #tray,
      #network,
      #backlight,
      #clock,
      #battery,
      #pulseaudio,
      #custom-lock,
      #custom-power {
        background-color: @surface0;
        padding: 0.5rem 1rem;
        margin: 5px 0;
      }

      #clock {
        color: @lavender;
        border-radius: 0px 1rem 1rem 0px;
        margin-right: 1rem;
      }

      #battery {
        color: @green;
      }

      #battery.charging {
        color: @green;
      }

      #battery.warning:not(.charging) {
        color: @red;
      }

      #network {
          color: @flamingo;
      }

      #backlight {
        color: @yellow;
      }

      #backlight, #battery {
          border-radius: 0;
      }

      #pulseaudio {
        color: @pink;
        border-radius: 1rem 0px 0px 1rem;
        margin-left: 1rem;
      }

      #pulseaudio.muted {
          color: @red;
      }


      #custom-music {
        color: @teal;
        border-radius: 1rem;
      }

      #custom-power {
          margin-right: 1rem;
          border-radius: 1rem;
          color: @red;
      }

      #tray {
        margin-right: 1rem;
        border-radius: 1rem;
      }
    '';
  };
}
