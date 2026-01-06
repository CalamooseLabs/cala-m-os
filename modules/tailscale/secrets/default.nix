{...}: {
  age = {
    secrets = {
      "tailscale-preauth-key" = {
        file = ./. + "/tailscale-preauth-key.age";
      };
    };
  };
}
