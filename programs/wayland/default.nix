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
      #
      # ========== Main Bar ==========
      #
      mainBar = {
        # layer = "top";
        # position = "top";
        # height = 36; # 36 is the minimum height required by the modules

        # output = [
        #   "eDP-1"
        #   "DP-5"
        #   "DP-6"
        # ];
        # modules-left = [
        #   "network"
        # ];
        # modules-center = [
        #   "clock#time"
        #   "clock#date"
        # ];
        # modules-right = [
        #   "pulseaudio"
        #   "battery"
        # ];

        # #
        # # ========= Modules =========
        # "clock#time" = {
        #   interval = 1;
        #   format = "{:%H:%M:%S}";
        #   tooltip = false;
        # };
        # "clock#date" = {
        #   interval = 10;
        #   format = "    {:%a. %b. %d %Y}";
        #   tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        # };
        # "network" = {
        #   format-wifi = "{essid} ({signalStrength}%)";
        #   format-ethernet = "ETH: {ipaddr}";
        #   tooltip-format = "{ifname} via {gwaddr}";
        #   format-linked = "{ifname} (No IP)";
        #   format-disconnected = "Disconnected ⚠";
        #   format-alt = "{ifname}: {ipaddr}/{cidr}";
        # };
        # "pulseaudio" = {
        #   "format" = "Volume: {volume}% {icon}";
        #   "scroll-step" = 1;
        #   "on-click" = "pavucontrol";
        #   "ignored-sinks" = [ "Easy Effects Sink" ];
        # };
        # "battery" = {
        #   "format" = "    Battery: {capacity}%";
        # };

        "layer" = "top"; # Waybar at top layer
        "position" = "top"; # Waybar position (top|bottom|left|right)
        # Choose the order of the modules
        "modules-left" = ["wlr/workspaces"];
        "modules-center" = ["custom/music"];
        "modules-right" = [
          "pulseaudio"
          "backlight"
          "battery"
          "clock"
          "tray"
          "custom/lock"
          "custom/power"
        ];
        "wlr/workspaces" = {
            "disable-scroll" = true;
            "sort-by-name" = true;
            "format" = " {icon} ";
            "format-icons" = {
                "default" = "";
            };
        };
        "tray" = {
          "icon-size" = 21;
            "spacing" = 10;
        };
        "custom/music" = {
            "format" = "  {}";
            "escape" = true;
            "interval" = 5;
            "tooltip" = false;
            "exec" ="playerctl metadata --format='{{ title }}'";
            "on-click" = "playerctl play-pause";
            "max-length" = 50;
        };
        "clock" = {
            "timezone" = "America/Chicago";
            "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            "format-alt" = " {:%d/%m/%Y}";
            "format" = " {:%H:%M}";
        };
        "backlight" = {
            "device" = "intel_backlight";
            "format" = "{icon}";
            "format-icons" = [
                ""
                ""
                ""
                ""
                ""
                ""
                ""
                ""
                ""
            ];
        };
        "battery" = {
            "states" = {
                "warning" = 30;
                "critical" = 15;
            };
            "format" = "{icon}";
            "format-charging" = "";
            "format-plugged" = "";
            "format-alt" = "{icon}";
            "format-icons" = [
                ""
                ""
                ""
                ""
                ""
                ""
                ""
                ""
                ""
                ""
                ""
                ""
              ];
            };
            "pulseaudio" = {
                "scroll-step" = 1; # %, can be a float
                "format" = "{icon} {volume}%";
                "format-muted" = "";
                "format-icons" = {
                    "default" = [
                      ""
                      ""
                      " "
                    ];
                };
                "on-click" = "pavucontrol";
            };
            "custom/lock" = {
                "tooltip" = false;
                "on-click" = "sh -c '(sleep 0.5s; swaylock --grace 0)' & disown";
                "format" = "";
            };
            "custom/power" = {
                "tooltip" = false;
                "on-click" = "wlogout &";
                "format" = "襤";
            };
      };
    };

    style = ''
      @define-color base   #1e1e2e;
      @define-color mantle #181825;
      @define-color crust  #11111b;

      @define-color text     #cdd6f4;
      @define-color subtext0 #a6adc8;
      @define-color subtext1 #bac2de;

      @define-color surface0 #313244;
      @define-color surface1 #45475a;
      @define-color surface2 #585b70;

      @define-color overlay0 #6c7086;
      @define-color overlay1 #7f849c;
      @define-color overlay2 #9399b2;

      @define-color blue      #89b4fa;
      @define-color lavender  #b4befe;
      @define-color sapphire  #74c7ec;
      @define-color sky       #89dceb;
      @define-color teal      #94e2d5;
      @define-color green     #a6e3a1;
      @define-color yellow    #f9e2af;
      @define-color peach     #fab387;
      @define-color maroon    #eba0ac;
      @define-color red       #f38ba8;
      @define-color mauve     #cba6f7;
      @define-color pink      #f5c2e7;
      @define-color flamingo  #f2cdcd;
      @define-color rosewater #f5e0dc;

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
        margin: 5px;
        background-color: @surface0;
        margin-left: 1rem;
      }

      #workspaces button {
        color: @lavender;
        border-radius: 1rem;
        padding: 0.4rem;
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
        color: @blue;
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

      #backlight {
        color: @yellow;
      }

      #backlight, #battery {
          border-radius: 0;
      }

      #pulseaudio {
        color: @maroon;
        border-radius: 1rem 0px 0px 1rem;
        margin-left: 1rem;
      }

      #custom-music {
        color: @mauve;
        border-radius: 1rem;
      }

      #custom-lock {
          border-radius: 1rem 0px 0px 1rem;
          color: @lavender;
      }

      #custom-power {
          margin-right: 1rem;
          border-radius: 0px 1rem 1rem 0px;
          color: @red;
      }

      #tray {
        margin-right: 1rem;
        border-radius: 1rem;
      }
    '';
  };
}
