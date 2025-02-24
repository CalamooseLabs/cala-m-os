{ pkgs, inputs, ... }:

{
  programs.zed-editor = {
    enable = true;

    extraPackages = [ pkgs.nixd ];

    extensions = [
      "nix"
    ];

    userSettings = {
      telemetry = {
        metrics = false;
        diagnostics = false;
      };

      vim_mode = true;
      autosave = "on_focus_change";
      restore_on_startup = "none";
      confirm_quit = false;
      load_direnv = "direct";

      auto_update = false;
      auto_check_updates = false;
      auto_install_extension = false;

      edit_predictions_disabled_in = [
        "comment"
        "string"
      ];

      hide_mouse_while_typing = true;
      ui_font_size = 16;
      buffer_font_size = 16;

      ensure_final_newline_on_save = true;
      format_on_save = "on";

      search = {
        whole_word = false;
        case_sensitivc = false;
        include_ignored = false;
        regex = true;
      };

      terminal = {
        button = false;
      };

      language_models = {
        ollama = {
          api_url = "http://ai.calamos.family:11434";
        };
      };

      assistant = {
        enabled = true;
        default_model = {
          provider = "ollama";
          model = "qwen2.5-coder:14b";
        };
        version = "2";
        button = true;
        dock = "right";
      };

      relative_line_numbers = true;
    };
  };
}
