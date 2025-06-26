{...}: {
  age = {
    secrets = {
      "work_credentials" = {
        file = ./. + "/work_credentials.age";
      };
    };
    identityPaths = [
      "/etc/nixos/modules/agenix/identities/yubi.key"
    ];
  };
}
