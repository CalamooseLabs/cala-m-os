let
  yubinano = "age1yubikey1qvqy8f2qhwprxg6wmpzec06f2gceze40jxx7x9tdxjzx6ag45uj9y8p96kt";
in {
  age.identityPaths = [
    "./identities/yubi.txt"
  ];

  "admin_password.age".publicKeys = [yubinano];
}
