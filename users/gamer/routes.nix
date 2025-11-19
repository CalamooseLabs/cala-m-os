{...}: {
  services.lanserver = {
    enable = true;
    port = 8080;
    runAsRoot = true;
    routes = [
      {
        path = "/";
        method = "GET";
        command = [
          "echo '=== System Info ==='"
          "nixos-version"
          "echo -e '\n=== CPU & Memory ==='"
          "top -bn1 | head -5"
          "echo -e '\n=== Disk Usage ==='"
          "df -h"
          "echo -e '\n=== Memory Usage ==='"
          "free -h"
        ];
      }
      {
        path = "/gaming";
        method = "GET";
        command = [
          "start-gaming"
        ];
      }
      {
        path = "/shutdown";
        method = "GET";
        command = [
          "echo 'Shutting down...'"
          "shutdown 0"
        ];
      }
      {
        path = "/restart";
        method = "GET";
        command = [
          "echo 'Restart...'"
          "sudo reboot"
        ];
      }
      {
        path = "/vm/start";
        method = "POST";
        data = {stationNumber = "string";};
        command = [
          "sudo systemctl start microvm@lanstation-$stationNumber.service"
        ];
      }
      {
        path = "/vm/status";
        method = "POST";
        data = {stationNumber = "string";};
        command = [
          "sudo systemctl status microvm@lanstation-$stationNumber.service | grep -Po '(?<=Active: )\w+'"
        ];
      }
      {
        path = "/audio/source";
        method = "POST";
        data = {source = "string";};
        command = [
          "stty -F /dev/ttyUSB0 115200 cs8 -cstopb -parenb && echo -n 's output audio $source!' > /dev/ttyUSB0"
        ];
      }
      {
        path = "/video/source";
        method = "POST";
        data = {source = "string";};
        command = [
          "stty -F /dev/ttyUSB0 115200 cs8 -cstopb -parenb && echo -n 's in source $source!' > /dev/ttyUSB0"
        ];
      }
      {
        path = "/video/multiview";
        method = "POST";
        data = {mode = "string";};
        command = [
          "stty -F /dev/ttyUSB0 115200 cs8 -cstopb -parenb && echo -n 's multiview $mode!' > /dev/ttyUSB0"
        ];
      }
    ];
  };
}
