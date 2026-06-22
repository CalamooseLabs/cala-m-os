{lib, ...}: {
  options.cala.lockscreen.background = lib.mkOption {
    type = lib.types.enum ["static" "dynamic"];
    default = "static";
    description = "Lockscreen (hyprlock) background mode: 'static' (still image) or 'dynamic' (drift frames pre-rendered at build and crossfaded on a timer).";
  };

  config.security.pam.services.hyprlock = {};
}
