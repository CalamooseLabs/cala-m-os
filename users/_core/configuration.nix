{username, ...}: {config, ...}: {
  users.users = {
    "${username}" = {
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.admin_password.path;
    };
  };
}
