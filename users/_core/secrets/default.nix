{lib, enable_secrets ? true, ...}: {
  age = lib.mkIf enable_secrets {
    secrets = {
      "admin_password" = {
        file = ./. + "/admin_password.age";
      };
    };
  };
}
