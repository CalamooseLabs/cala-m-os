{
  inputs,
  pkgs,
  ...
}: {
  # `antlers` (antlers): the shorthand CLI over the antlers flake — `antlers new`,
  # `antlers init`, `antlers build`, `antlers run`, `antlers develop` against
  # github:CalamooseLabs/antlers (override per-invocation with ANTLERS_REF). The
  # package bundles its bash completion (resolved by bash-completion's lazy
  # loader), so the `bash` module gives `antlers <TAB>` subcommand + live
  # template/package completion. A zero-config wrapper, consumed as a plain
  # package like chromium-ephemeral.
  home.packages = [inputs.antlers.packages.${pkgs.stdenv.hostPlatform.system}.antlers];
}
