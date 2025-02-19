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
        layer = "top";
        position = "top";
        height = 36; # 36 is the minimum height required by the modules
        #FIXME(hyprland): make use of monitors module
        output = [
          "eDP-1"
          "DP-5"
          "DP-6"
        ];
        modules-left = [
          "network"
        ];
        modules-center = [
          "clock#time"
          "clock#date"
        ];
        modules-right = [
          "pulseaudio"
          "battery"
        ];

        #
        # ========= Modules =========
        "clock#time" = {
          interval = 1;
          format = "{:%H:%M:%S}";
          tooltip = false;
        };
        "clock#date" = {
          interval = 10;
          format = "    {:%a. %b. %d %Y}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
        "network" = {
          format-wifi = "{essid} ({signalStrength}%)";
          format-ethernet = "ETH: {ipaddr}";
          tooltip-format = "{ifname} via {gwaddr}";
          format-linked = "{ifname} (No IP)";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
        };
        "pulseaudio" = {
          "format" = "Volume: {volume}%";
          "scroll-step" = 1;
          "on-click" = "pavucontrol";
          "ignored-sinks" = [ "Easy Effects Sink" ];
        };
        "battery" = {
          "format" = "    Battery: {capacity}%";
        };
      };
    };
  };
}
