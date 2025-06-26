{...}: {
  age = {
    secrets = {
      "yubigpg.asc" = {
        file = ./. + "/yubigpg.asc.age";
      };
    };
    identityPaths = [
      "/etc/nixos/modules/agenix/identities/yubi.key"
    ];
  };
}
