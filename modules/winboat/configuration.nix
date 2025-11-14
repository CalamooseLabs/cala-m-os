{cala-m-os, ...}: {
  virtualisation.docker = {
    enable = true;
  };

  users.users."${cala-m-os.globals.defaultUser}" = {
    extraGroups = [
      "docker"
    ];
  };
}
