{username, ...}: {config, lib, ...}: {
  users.users."${username}" = {
    isNormalUser = true;
    hashedPasswordFile = lib.mkIf config.calamoose.enableSecrets config.age.secrets.admin_password.path;
  };
}
