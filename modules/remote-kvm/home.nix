{pkgs, ...}: let
  # Minimal-chrome stylesheet: hide tab bar, nav/toolbar, bookmarks, etc.
  userChrome = pkgs.writeText "userChrome.css" ''
    /* Hide the whole top toolbar area (tabs, urlbar, bookmarks) */
    #TabsToolbar { visibility: collapse !important; }
    #nav-bar { visibility: collapse !important; }
    #PersonalToolbar { visibility: collapse !important; }
    #titlebar { display: none !important; }

    /* Drop the leftover padding so content fills the window */
    #navigator-toolbox { border: none !important; }
  '';

  # Prefs that enable userChrome.css and trim the rest of the UI.
  userJs = pkgs.writeText "user.js" ''
    // Allow userChrome.css customizations
    user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
    // No bookmarks toolbar
    user_pref("browser.toolbars.bookmarks.visibility", "never");
    // Don't restore a previous session / show what's-new etc.
    user_pref("browser.aboutwelcome.enabled", false);
    user_pref("browser.startup.homepage_override.mstone", "ignore");
    // Skip the "is your default browser" nags
    user_pref("browser.shell.checkDefaultBrowser", false);

    // Allow plain HTTP without the "connection not secure" interstitial.
    // Librewolf turns HTTPS-Only Mode on by default; the KVM is http-only.
    user_pref("dom.security.https_only_mode", false);
    user_pref("dom.security.https_only_mode_ever_enabled", false);
    // Don't warn when submitting forms / entering an insecure page.
    user_pref("security.insecure_field_warning.contextual.enabled", false);
    user_pref("security.warn_submit_secure_to_insecure", false);

    // Dark mode: force dark UI theme and tell web content to render dark.
    user_pref("ui.systemUsesDarkTheme", 1);
    user_pref("layout.css.prefers-color-scheme.content-override", 0); // 0 = dark
    user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");
    user_pref("browser.theme.toolbar-theme", 0); // 0 = dark
    user_pref("browser.theme.content-theme", 0); // 0 = dark
  '';
in {
  home.packages = [
    (pkgs.writeShellScriptBin "remote-kvm" ''
      set -eux

      kvm_url="http://broadcast.thecompany.inc"

      # Dedicated, throwaway-ish profile so the main profile stays untouched.
      profile="$HOME/.local/share/remote-kvm/profile"
      mkdir -p "$profile/chrome"
      install -m644 ${userChrome} "$profile/chrome/userChrome.css"
      install -m644 ${userJs} "$profile/user.js"

      exec ${pkgs.librewolf}/bin/librewolf \
        --profile "$profile" \
        --no-remote \
        "$kvm_url"
    '')
  ];
}
