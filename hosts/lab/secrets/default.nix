{lib, config, ...}: {
  age = lib.mkIf config.calamoose.enableSecrets {
    secrets = {
      "cloudflare-token" = {
        file = ./. + "/cloudflare-token.age";
      };
      "qbit-password" = {
        file = ./. + "/qbit-password.age";
      };
      "proton-vpn.conf" = {
        file = ./. + "/proton-vpn.conf.age";
      };
    };
  };
}
