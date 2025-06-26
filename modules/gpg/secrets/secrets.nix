let
  yubinano = "age1yubikey1qvqy8f2qhwprxg6wmpzec06f2gceze40jxx7x9tdxjzx6ag45uj9y8p96kt";
in {
  "yubigpg.asc.age".publicKeys = [yubinano];
}
