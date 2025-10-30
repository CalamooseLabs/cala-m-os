{...}: {
  services.pcscd.enable = true;

  systemd.services.pcscd = {
    wantedBy = ["multi-user.target"];
    before = ["multi-user.target"];
  };
}
