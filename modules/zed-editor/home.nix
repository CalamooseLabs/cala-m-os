{lib, ...}: {
  programs.zed-editor = {
    enable = true;

    extraPackages = [
    ];

    extensions = [
    ];

    userSettings = {
      telemetry = {
        metrics = false;
        diagnostics = false;
      };

      vim_mode = true;
      autosave = "on_focus_change";
      restore_on_startup = "empty_tab";
      confirm_quit = false;
      load_direnv = "shell_hook";
      auto_update = false;

      hide_mouse = "on_typing";
      tab_size = 2;

      ensure_final_newline_on_save = true;
      format_on_save = "on";

      search = {
        whole_word = false;
        case_sensitive = false;
        include_ignored = false;
        regex = true;
      };

      theme = lib.mkForce {
        mode = "system";
        light = "One Light";
        dark = "One Dark";
      };

      terminal = {
        button = false;
      };

      disable_ai = true;
      relative_line_numbers = "enabled";

      auto_install_extensions = {
        "html" = false;
      };
    };
  };
}
