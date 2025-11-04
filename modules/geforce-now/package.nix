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
in
  pkgs.appimageTools.wrapType2 {
    inherit name src version pname;

    extraPkgs = pkgs:
      with pkgs; [
        # Core dependencies
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

        # Additional Electron dependencies
        libxkbcommon
        mesa.drivers
        vulkan-loader
        libGL
        libglvnd
        egl-wayland
        wayland
        xorg.libxcb
        xorg.libX11
        xorg.libXext
        xorg.libXi
        xorg.libXrandr
        xorg.libXrender
        xorg.libXtst
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXcomposite
        xorg.libXfixes
        xorg.libXinerama
        xorg.libXScrnSaver
        xorg.libXxf86vm
        xorg.xcbutilimage
        xorg.xcbutilkeysyms
        xorg.xcbutilrenderutil
        xorg.xcbutilwm
      ];

    extraBuildCommands = ''
      mkdir -p $out/etc/nixos
    '';

    meta = with lib; {
      description = "GeForce NOW Electron Wrapper for Linux";
      homepage = "https://github.com/hmlendea/gfn-electron";
      license = licenses.gpl3;
      maintainers = [];
      platforms = ["x86_64-linux"];
    };
  }
