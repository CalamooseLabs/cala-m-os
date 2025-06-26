{...}: {
  age = {
    secrets = {
      "admin_password" = {
        file = ./. + "/admin_password.age";
      };
    };
    identityPaths = [
      "/etc/nixos/modules/agenix/identities/yubi.key"
    ];
  };
}
