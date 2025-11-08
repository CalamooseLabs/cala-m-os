{...}: {
  systemd.services.agenix-rerun = {
    description = "Rerun agenix decryption after boot";
    after = ["pcscd.service"];
    requires = ["pcscd.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Rerun the activation script
      /run/current-system/activate
    '';
  };
}
