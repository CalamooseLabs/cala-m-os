{username, ...}: {config, ...}: {
  users.users."${username}" = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.admin_hash.path;
    extraGroups = [];
  };
}
