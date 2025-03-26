{pkgs, ...}: {
  home.packages = [
    pkgs.dnsmasq
    pkgs.nftables
  ];

  # Install the script from the external file
  home.file.".local/bin/share-internet" = {
    source = ./scripts/share-internet.sh;
    executable = true;
  };

  # Make sure ~/.local/bin is in your PATH
  home.sessionVariables = {
    PATH = "$HOME/.local/bin:$PATH";
  };
}
