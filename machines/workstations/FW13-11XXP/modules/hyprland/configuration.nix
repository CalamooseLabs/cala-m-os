{...}: {
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    lidSwitch = "ignore";
    lidSwitchExternalPower = "ignore";
    lidSwitchDocked = "ignore";
  };
}
