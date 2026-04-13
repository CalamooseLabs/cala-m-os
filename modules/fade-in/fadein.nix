{
  lib,
  stdenv,
  autoPatchelfHook,
  makeWrapper,
  qt5,
  libGL,
  fontconfig,
  freetype,
  xorg,
  alsa-lib,
  libpulseaudio,
  cups,
  zlib,
  glib,
}:
stdenv.mkDerivation {
  pname = "fadein";
  version = "5.0.11"; # Update to match your version

  # Reference the local tar.gz file (relative to this .nix file)
  src = ./packages/fadein-linux-x64.tar.gz;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    qt5.wrapQtAppsHook
  ];

  buildInputs = [
    qt5.qtbase
    qt5.qtsvg
    qt5.qtmultimedia
    qt5.qtwayland
    libGL
    fontconfig
    freetype
    xorg.libX11
    xorg.libXrender
    xorg.libXext
    xorg.libXi
    xorg.libxcb
    alsa-lib
    libpulseaudio
    cups
    zlib
    glib
    stdenv.cc.cc.lib # For libstdc++
  ];

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Create directories
    mkdir -p $out/bin
    mkdir -p $out/share/fadein
    mkdir -p $out/share/applications
    mkdir -p $out/share/pixmaps

    # Copy all files (adjust based on actual tar.gz structure)
    # First, let's see what's in the archive - you may need to adjust these paths
    cp -r * $out/share/fadein/ || true

    # Find and link the main binary
    if [ -f "$out/share/fadein/fadein" ]; then
      chmod +x $out/share/fadein/fadein
      ln -s $out/share/fadein/fadein $out/bin/fadein
    elif [ -f "$out/share/fadein/FadeIn" ]; then
      chmod +x $out/share/fadein/FadeIn
      ln -s $out/share/fadein/FadeIn $out/bin/fadein
    fi

    # Create desktop entry
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

  meta = with lib; {
    homepage = "https://www.fadeinpro.com";
    description = "Professional screenwriting software";
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
    mainProgram = "fadein";
  };
}
