{...}: {
  age = {
    secrets = {
      "work_credentials" = {
        file = ./. + "/work_credentials.age";
      };
    };
  };
}
