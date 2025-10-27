{username, ...}: {config, ...}: {
  users.users = {
    "${username}" = {
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.admin_password.path or "/run/agenix/admin_password";
    };
  };
}
