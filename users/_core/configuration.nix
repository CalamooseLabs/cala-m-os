{username, ...}: {...}: {
  users.users = {
    "${username}" = {
      isNormalUser = true;
    };
  };
}
