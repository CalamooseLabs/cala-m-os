{...}: {
  age = {
    secrets = {
      "plex-cloudflare-token" = {
        file = ./. + "/plex-cloudflare-token.age";
      };
    };
    identityPaths = [
      "/etc/nixos/modules/agenix/identities/yubi.key"
    ];
  };
}
