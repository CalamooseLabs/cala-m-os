{pkgs, ...}: {
  home.packages = [
    pkgs.dnsmasq
    pkgs.nftables
  ];

  # Install the script from the external file
  home.file.".local/bin/bridge-internet" = {
    source = ./scripts/bridge-internet.sh;
    executable = true;
  };

  # Make sure ~/.local/bin is in your PATH
  home.sessionVariables = {
    PATH = "$HOME/.local/bin:$PATH";
  };
}
