let
  yubinano = "age1yubikey1qvqy8f2qhwprxg6wmpzec06f2gceze40jxx7x9tdxjzx6ag45uj9y8p96kt";
  yubiserver = "age1yubikey1qfswg89kkc7yvfxg3a9z56q9pl7vfzzvqfcuaka8svut7p45shy2zuxv8c2";
in {
  "cloudflare-token.age".publicKeys = [
    yubinano
    yubiserver
  ];
}
