{lib, enable_secrets ? true, ...}: {
  age = lib.mkIf enable_secrets {
    secrets = {
      "work_credentials" = {
        file = ./. + "/work_credentials.age";
      };
      "proton_vpn.conf" = {
        file = ./. + "/proton_vpn.conf.age";
      };
    };
  };
}
