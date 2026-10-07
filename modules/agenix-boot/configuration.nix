# Superseded: the post-boot re-run now ships as `agenix-rerun.service` in
# modules/agenix/configuration.nix (every agenix host gets it). This shelf
# module is kept only as a record of the original sketch below.
{...}: {
  # systemd.services.agenix-rerun = {
  #   description = "Rerun agenix decryption after boot";
  #   after = ["pcscd.service"];
  #   requires = ["pcscd.service"];
  #   wantedBy = ["multi-user.target"];

  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };

  #   script = ''
  #     # Rerun the activation script
  #     /run/current-system/activate
  #   '';
  # };
}
