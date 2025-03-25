{username, ...}: {config, ...}: {
  sops = {
    secrets = {
      admin_hash = {
        neededForUsers = true;
        sopsFile = ./secrets/users.json;
        format = "json";
      };
    };
  };

  users.users = {
    "${username}" = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.admin_hash.path;
    };
  };
}
