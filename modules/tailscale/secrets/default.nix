{...}: {
  age = {
    secrets = {
      "tailscale-preauth-key" = {
        file = ./. + "/tailscale-preauth-key.age";
      };
    };
    identityPaths = [
      "/etc/nixos/modules/agenix/identities/yubi.key"
    ];
  };
}
