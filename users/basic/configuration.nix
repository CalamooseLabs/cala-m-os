{username, ...}: {...}: {
  users.users."${username}" = {
    extraGroups = [];
  };
}
