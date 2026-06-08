{lib, enable_secrets ? true, ...}: {
  age = lib.mkIf enable_secrets {
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
