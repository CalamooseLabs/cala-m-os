let
  yubinano = "age1yubikey1qvqy8f2qhwprxg6wmpzec06f2gceze40jxx7x9tdxjzx6ag45uj9y8p96kt";
  yubiserver = "age1yubikey1qwswvpt2rzs97gk5ktacd4xy0yr4rdls8uex2xpqvyrekdct74jkc0g0a4v";
  yubibackup = "age1yubikey1qgychggwa5q2mc52u2w6xqznl7z9luadghvxhhtjl2k8pgjudh4z5cny283";
in {
  # UniFi Protect integration API key — consumed by the `security` microVM via /run/hostsecrets.
  "protect-api-key.age".publicKeys = [
    yubiserver
    yubinano
    yubibackup
  ];
  # UniFi-OS local-admin password for recorded-video playback (the `security` VM).
  "protect-admin-password.age".publicKeys = [
    yubiserver
    yubinano
    yubibackup
  ];
}
