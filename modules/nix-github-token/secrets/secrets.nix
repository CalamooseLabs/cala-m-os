# agenix recipients for the Nix GitHub build token (offline/agenix hosts, e.g. devbox).
# Same Yubikey recipients as the rest of the tree. Create/edit the encrypted file with:
#   cd modules/nix-github-token/secrets && agenix -e nix-github-token.age
# The plaintext must be the literal nix.conf directive line:
#   access-tokens = github.com=github_pat_XXXXXXXXXXXXXXXXXXXX
let
  yubinano = "age1yubikey1qvqy8f2qhwprxg6wmpzec06f2gceze40jxx7x9tdxjzx6ag45uj9y8p96kt";
  yubibackup = "age1yubikey1qgychggwa5q2mc52u2w6xqznl7z9luadghvxhhtjl2k8pgjudh4z5cny283";
in {
  "nix-github-token.age".publicKeys = [
    yubinano
    yubibackup
  ];
}
