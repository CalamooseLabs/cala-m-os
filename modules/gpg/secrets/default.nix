{...}: {
  age = {
    secrets = {
      "yubigpg.asc" = {
        file = ./. + "/yubigpg.asc.age";
      };
    };
  };
}
