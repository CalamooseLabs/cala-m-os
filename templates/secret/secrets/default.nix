{...}: {
  age = {
    secrets = {
      "secret" = {
        file = ./. + "/secret.age";
      };
    };
    identityPaths = [
      "/etc/nixos/modules/agenix/identities/yubi.key"
    ];
  };
}
