let
  yubinano = "age1yubikey1qvqy8f2qhwprxg6wmpzec06f2gceze40jxx7x9tdxjzx6ag45uj9y8p96kt";
in {
  age.identityPaths = [
    "./identities/yubi.txt"
    "/etc/nixos/modules/agenix/identities/yubi.key"
  ];

  "secret.age".publicKeys = [yubinano];
}
