{...}: {
  age = {
    secrets = {
      "work_credentials" = {
        file = ./. + "/work_credentials.age";
      };
      "proton_vpn.conf" = {
        file = ./. + "/proton_vpn.conf.age";
      };
    };
    identityPaths = [
      "/etc/nixos/modules/agenix/identities/yubi.key"
    ];
  };
}
