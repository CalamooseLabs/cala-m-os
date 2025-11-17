{inputs, ...}: {
  imports = [
    inputs.lanserver.nixosModules.lanserver
  ];

  services.lanserver = {
    enable = true;
    port = 8080;
    runAsRoot = true;
    routes = [
      {
        path = "/shutdown";
        method = "GET";
        command = [
          "echo"
          "Shutting down..."
          "shutdown"
          "0"
        ];
      }
      {
        path = "/status";
        method = "POST";
        data = {
          serviceName = "string";
        };
        command = [
          "systemctl"
          "status"
          "$serviceName"
        ];
      }
    ];
  };
}
