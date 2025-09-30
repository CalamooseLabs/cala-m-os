let
  yubinano = "age1yubikey1qvqy8f2qhwprxg6wmpzec06f2gceze40jxx7x9tdxjzx6ag45uj9y8p96kt";
  yubibackup = "age1yubikey1qgychggwa5q2mc52u2w6xqznl7z9luadghvxhhtjl2k8pgjudh4z5cny283";
in {
  "tailscale-preauth-key.age".publicKeys = [
    yubinano
    yubibackup
  ];
}
