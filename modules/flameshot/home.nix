{
  pkgs,
  cala-m-os,
  ...
}: {
  home.packages = with pkgs; [
    grim
  ];

  services.flameshot = {
    enable = true;
    settings = {
      General = {
        savePath = "/home/${cala-m-os.globals.defaultUser}/00 - Inbox";
        # Tray
        disabledTrayIcon = true;
        # Greeting message
        showStartupLaunchMessage = false;
        # Default file extension for screenshots (.png by default)
        saveAsFileExtension = ".png";
        # Desktop notifications
        showDesktopNotification = false;
        # Notification for cancelled screenshot
        showAbortNotification = false;
        # Whether to show the info panel in the center in GUI mode
        showHelp = true;
        # Whether to show the left side button in GUI mode
        showSidePanelButton = true;

        # Color Customization
        uiColor = "#740096";
        contrastUiColor = "#270032";
        drawColor = "#ff0000";

        # For Wayland (Install Grim seperately)
        useGrimAdapter = true;
        # Stops warnings for using Grim
        disabledGrimWarning = true;
      };
    };
  };

  wayland.windowManager.hyprland.settings.bind = [
    "$mod SHIFT, S, exec, flameshot gui"
    ", Print, exec, flameshot gui"
  ];
}
