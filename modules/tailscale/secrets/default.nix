{lib, enable_secrets ? true, ...}: {
  age = lib.mkIf enable_secrets {
    secrets = {
      "tailscale-preauth-key" = {
        file = ./. + "/tailscale-preauth-key.age";
      };
    };
  };
}
