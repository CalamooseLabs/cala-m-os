{username, ...}: {
  config,
  lib,
  ...
}: {
  users.users."${username}" = {
    isNormalUser = true;
    hashedPasswordFile = lib.mkIf config.calamoose._secretsEnabled config.calamoose.secrets.admin_password.path;
  };
}
