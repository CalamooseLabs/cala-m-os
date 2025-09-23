{...}: {
  age = {
    secrets = {
      "plex-cloudflare-token" = {
        file = ./. + "/plex-cloudflare-token.age";
        owner = "caddy";
        group = "caddy";
        mode = "400";
      };
    };
    identityPaths = [
      "/etc/nixos/modules/agenix/identities/yubi.key"
    ];
  };
}
