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
        path = "/vm/status/2";
        method = "GET";
        command = [
          "sudo systemctl status microvm@lanstation-2.service | grep -Po '(?<=Active: )\w+'"
        ];
      }
      {
        path = "/vm/status/3";
        method = "GET";
        command = [
          "sudo systemctl status microvm@lanstation-3.service | grep -Po '(?<=Active: )\w+'"
        ];
      }
      {
        path = "/vm/status/4";
        method = "GET";
        command = [
          "sudo systemctl status microvm@lanstation-4.service | grep -Po '(?<=Active: )\w+'"
        ];
      }
    ];
  };
}
# stty -F /dev/ttyUSB0 115200 cs8 -cstopb -parenb && echo -n "power 0!" > /dev/ttyUSB0

