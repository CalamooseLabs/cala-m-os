{pkgs, ...}: {
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
        modules-right = ["pulseaudio" "network" "backlight" "battery" "clock" "custom/power"];

        "wlr/workspaces" = {
          disable-scroll = true;
          sort-by-name = true;
          format = "{icon}";
          format-icons = {default = "";};
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
      };
    };

    style = builtins.readFile ./style.css;
  };
}
