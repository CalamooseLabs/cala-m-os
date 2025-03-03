{ pkgs, ... }: zedSettings:

pkgs.runCommand "zed-wrapped" {
  buildInputs = [ pkgs.makeWrapper ];
  zedSettingsJSON = builtins.toJSON zedSettings;
} ''
  mkdir -p $out/bin

  # Create the zed wrapper with inline configuration
  makeWrapper ${pkgs.zed-editor}/bin/zeditor $out/bin/zeditor \
    --set OVERRIDE_SETTINGS "$zedSettingsJSON" \
    --run '
      ZED_CONFIG=".config/zed"
      SETTINGS_PATH="$HOME/$ZED_CONFIG"
      OVERRIDE_PATH="$PWD/.direnv/$ZED_CONFIG"

      mkdir -p "$OVERRIDE_PATH"

      if [ -d "$SETTINGS_PATH/themes" ]; then
        cp -r "$SETTINGS_PATH/themes" "$OVERRIDE_PATH"
      fi

      TEMP_FILE=$(mktemp)

      echo "$OVERRIDE_SETTINGS" | ${pkgs.jq}/bin/jq "." > "$TEMP_FILE"

      if [ -f "$SETTINGS_PATH/settings.json" ]; then
        ${pkgs.jq}/bin/jq -s ".[0] * .[1]" "$SETTINGS_PATH/settings.json" "$TEMP_FILE" > "$OVERRIDE_PATH/settings.json"
      else
        cp "$TEMP_FILE" "$OVERRIDE_PATH/settings.json"
      fi

      rm "$TEMP_FILE"

      export XDG_CONFIG_HOME="$PWD/.direnv/.config"
    '
''
