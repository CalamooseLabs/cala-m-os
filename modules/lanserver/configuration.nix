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
          "echo 'Shutting down...'"
          "shutdown 0"
        ];
      }
      {
        path = "/status";
        method = "POST";
        data = {
          serviceName = "string";
        };
        command = [
          "sudo systemctl status $serviceName"
        ];
      }
      {
        path = "/restart-nginx";
        method = "GET";
        command = [
          "echo 'Restarting nginx...'"
          "sudo systemctl restart nginx"
          "echo 'Nginx restarted successfully'"
        ];
      }
    ];
  };
}
