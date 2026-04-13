{
  lib,
  stdenv,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook,
  # GTK3 dependencies
  gtk3,
  gdk-pixbuf,
  pango,
  cairo,
  webkitgtk_4_1,
  # Other dependencies
  glib,
  fontconfig,
  curl,
  xorg,
  libxkbcommon,
  wayland,
  util-linux,
}:
stdenv.mkDerivation rec {
  pname = "fadein";
  version = "5.0.11";

  src = ./packages/fadein-linux-x64.tar.gz;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook
  ];

  buildInputs = [
    # GTK3 stack
    gtk3
    gdk-pixbuf
    pango
    cairo
    webkitgtk_4_1

    # Core libs
    glib
    fontconfig
    curl
    libxkbcommon
    wayland
    util-linux # for libuuid

    # X11
    xorg.libX11
    xorg.libSM
    xorg.libICE

    # Standard C++ lib
    stdenv.cc.cc.lib
  ];

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
        runHook preInstall

        # The tar extracts to: fadein-linux-x86_64-5.0.11/usr/share/fadein/
        mkdir -p $out/bin
        mkdir -p $out/share/fadein
        mkdir -p $out/share/applications
        mkdir -p $out/share/icons

        # Copy application files from the extracted structure
        cp -r fadein-linux-x86_64-${version}/usr/share/fadein/* $out/share/fadein/

        # Make binary executable and create symlink
        chmod +x $out/share/fadein/fadein
        ln -s $out/share/fadein/fadein $out/bin/fadein

        # Copy desktop file if it exists
        if [ -d "fadein-linux-x86_64-${version}/usr/share/applications" ]; then
          cp -r fadein-linux-x86_64-${version}/usr/share/applications/* $out/share/applications/ || true
        fi

        # Copy icons if they exist
        if [ -d "fadein-linux-x86_64-${version}/usr/share/icons" ]; then
          cp -r fadein-linux-x86_64-${version}/usr/share/icons/* $out/share/icons/ || true
        fi

        # Create desktop entry if not provided
        cat > $out/share/applications/fadein.desktop << EOF
    [Desktop Entry]
    Type=Application
    Name=Fade In
    Comment=Professional Screenwriting Software
    Exec=$out/bin/fadein %F
    Icon=fadein
    Terminal=false
    Categories=Office;WordProcessor;
    MimeType=application/x-fadein;
    EOF

        runHook postInstall
  '';

  # Don't wrap twice - wrapGAppsHook handles GTK apps
  dontWrapGApps = false;

  meta = with lib; {
    homepage = "https://www.fadeinpro.com";
    description = "Professional screenwriting software";
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
    mainProgram = "fadein";
  };
}
