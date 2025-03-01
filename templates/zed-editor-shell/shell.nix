{ pkgs }:

let
  zedSettings = {
    "assistant" = {
      "button" = true;
      "default_model" = {
        "model" = "qwen2.5-coder =14b";
        "provider" = "ollama";
      };
      "dock" = "right";
      "enabled" = true;
      "version" = "2";
    };
    "auto_check_updates" = false;
    "auto_install_extensions" = {
      "nix" = true;
    };
    "auto_update" = false;
    "autosave" = "on_focus_change";
    "buffer_font_family" = "MesloLGS NF";
    "buffer_font_size" = 16;
    "confirm_quit" = false;
    "edit_predictions_disabled_in" = [
      "comment"
      "string"
    ];
    "ensure_final_newline_on_save" = true;
    "format_on_save" = "on";
    "hide_mouse_while_typing" = true;
    "language_models" = {
      "ollama" = {
        "api_url" = "http://ai.calamos.family:11434";
      };
    };
    "load_direnv" = "direct";
    "lsp" = {
      "nix" = {
        "binary" = {
          "path_lookup" = true;
        };
      };
    };
    "relative_line_numbers" = true;
    "restore_on_startup" = "none";
    "search" = {
      "case_sensitivc" = false;
      "include_ignored" = false;
      "regex" = true;
      "whole_word" = false;
    };
    "tab_size" = 2;
    "telemetry" = {
      "diagnostics" = false;
      "metrics" = false;
    };
    "terminal" = {
      "button" = false;
    };
    "theme" = {
      "dark" = "Catppuccin Mocha";
      "light" = "Catppuccin Mocha";
    };
    "ui_font_family" = "MesloLGS NF";
    "ui_font_size" = 14;
    "vim_mode" = true;
  };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    jq
  ];

  packages = with pkgs; [
    zed-zed-editor
  ];

  shellHook = ''
    ZED_CONFIG_PATH=".config/zed";
    XDG_CONFIG_PATH="$TMPDIR"
  '';
}
