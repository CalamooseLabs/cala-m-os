{...}: {
  # Polkit rule for ashell wifi access
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        action.id == "org.freedesktop.NetworkManager.settings.modify.system" &&
        subject.isInGroup("networkmanager") &&
        subject.active
      ) {
        return polkit.Result.YES;
      }
    });
  '';

  services.upower.enable = true;
}
