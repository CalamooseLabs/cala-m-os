{
  username,
  enable_secrets ? true,
  ...
}: {config, lib, ...}: {
  users.users."${username}" = {
    isNormalUser = true;
    hashedPasswordFile = lib.mkIf enable_secrets config.age.secrets.admin_password.path;
  };
}
