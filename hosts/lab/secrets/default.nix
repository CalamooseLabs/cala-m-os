{...}: {
  age = {
    secrets = {
      "cloudflare-token" = {
        file = ./. + "/cloudflare-token.age";
      };
      "qbit-password" = {
        file = ./. + "/qbit-password.age";
        owner = "qbittorrent";
        group = "qbittorrent";
        mode = "770";
      };
      "proton-vpn.conf" = {
        file = ./. + "/proton-vpn.conf.age";
      };
    };
    identityPaths = [
      "/etc/nixos/modules/agenix/identities/server.key"
      "/etc/nixos/modules/agenix/identities/yubi.key"
    ];
  };
}
