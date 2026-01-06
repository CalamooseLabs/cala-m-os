{...}: {
  age = {
    secrets = {
      "admin_password" = {
        file = ./. + "/admin_password.age";
      };
    };
  };
}
