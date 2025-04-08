{...}: {
  age = {
    secrets = {
      "secret" = {
        file = ./. + "/secret.age";
      };
    };
  };
}
