let
  yubinano = "age1yubikey1qvqy8f2qhwprxg6wmpzec06f2gceze40jxx7x9tdxjzx6ag45uj9y8p96kt";
  yubibackup = "age1yubikey1qgychggwa5q2mc52u2w6xqznl7z9luadghvxhhtjl2k8pgjudh4z5cny283";
in {
  "CalamooseWiFi.nmconnection.age".publicKeys = [
    yubinano
    yubibackup
  ];
  "CalamooseLabs.nmconnection.age".publicKeys = [
    yubinano
    yubibackup
  ];
  "NKCWiFi.nmconnection.age".publicKeys = [
    yubinano
    yubibackup
  ];
  "theisenair.nmconnection.age".publicKeys = [
    yubinano
    yubibackup
  ];
  "NETGEAR43.nmconnection.age".publicKeys = [
    yubinano
    yubibackup
  ];
}
