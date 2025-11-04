{
  pkgs,
  lib,
  ...
}: let
  pname = "geforce-now";
  version = "2.2.0";
  name = "${pname}-${version}";

  src = pkgs.fetchurl {
    url = "https://github.com/hmlendea/gfn-electron/releases/download/v${version}/geforcenow-electron_${version}_linux.AppImage";
    sha256 = "n3ZsRXeFFidbqdtqzn3rHFtQiVjei5On1CtwKOwt7ac=";
  };

  appimageContents = pkgs.appimageTools.extractType2 {inherit src version pname;};
in
  pkgs.appimageTools.wrapType2 rec {
    inherit name src version pname;

    extraPkgs = pkgs:
      with pkgs; [
        # Add necessary runtime dependencies
        gtk3
        glib
        nss
        nspr
        alsa-lib
        dbus
        atk
        cups
        libdrm
        xorg.libXcomposite
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXi
        xorg.libXrandr
        xorg.libXrender
        xorg.libXtst
        xorg.xcbutilwm
        gdk-pixbuf
        cairo
        pango
        expat
        fontconfig
        freetype
        zlib
      ];

    extraBuildCommands = ''
      # Create an empty /etc/nixos directory to satisfy the app
      mkdir -p $out/etc/nixos
      # Leave it empty - the app just needs the directory to exist
    '';

    meta = with lib; {
      description = "GeForce NOW Electron Wrapper for Linux";
      homepage = "https://github.com/hmlendea/gfn-electron";
      license = licenses.gpl3;
      maintainers = [];
      platforms = ["x86_64-linux"];
    };
  }
