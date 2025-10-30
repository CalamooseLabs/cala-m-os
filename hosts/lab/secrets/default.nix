{...}: {
  age = {
    secrets = {
      "cloudflare-token" = {
        file = ./. + "/cloudflare-token.age";
      };
    };
    identityPaths = [
      "/etc/nixos/modules/agenix/identities/server.key"
    ];
  };
}
