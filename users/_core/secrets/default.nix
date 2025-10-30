{...}: {
  age = {
    secrets = {
      "admin_password" = {
        file = ./. + "/admin_password.age";
      };
    };
    identityPaths = [
      "/etc/nixos/modules/agenix/identities/server.key"
      "/etc/nixos/modules/agenix/identities/yubi.key"
      "/etc/nixos/modules/agenix/identities/dev.key"
      "/etc/nixos/modules/agenix/identities/backup.key"
    ];
  };
}
