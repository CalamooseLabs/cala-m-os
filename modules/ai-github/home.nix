# ai-github (home) — override the git identity to the bot, and auto-wake the card.
#
# Imported into the `ai` box's primary user (hub) via extra_user_modules. The
# shared git module (modules/git/home.nix) sets the personal identity + signing
# key at normal priority; mkForce here replaces them with the ai bot identity.
{
  lib,
  pkgs,
  ...
}: let
  # Per-boot one-shot: wake the card so gpg-agent offers the [A] subkey over SSH
  # immediately, and (re)import the bot public key — important on this impermanent
  # box after a full reinstall, when ~/.gnupg starts empty. Both steps are
  # idempotent and best-effort (they no-op when the card is absent).
  initScript = pkgs.writeShellScript "gpg-github-init" ''
    export PATH=/run/wrappers/bin:/run/current-system/sw/bin:$PATH
    ${pkgs.gnupg}/bin/gpg --card-status >/dev/null 2>&1 || true
    if command -v gpg-key-import >/dev/null 2>&1; then
      gpg-key-import >/dev/null 2>&1 || true
    fi
  '';
in {
  # This user IS the ai automation account — author + sign as the bot identity.
  programs.git.settings.user.email = lib.mkForce "ai@calamos.family"; # must be VERIFIED on the bot GitHub account
  programs.git.signing.key = lib.mkForce "REPLACE_ME_BOT_KEYID"; # <- from yubikey-github-bootstrap

  systemd.user.services.gpg-github-init = {
    Unit.Description = "Wake the Yubikey for gpg-agent SSH + import the ai bot GPG public key";
    Service = {
      Type = "oneshot";
      ExecStart = "${initScript}";
    };
    Install.WantedBy = ["default.target"];
  };
}
