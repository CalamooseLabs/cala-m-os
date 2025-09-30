let
  yubinano = "age1yubikey1qvqy8f2qhwprxg6wmpzec06f2gceze40jxx7x9tdxjzx6ag45uj9y8p96kt";
  yubidev = "age1yubikey1qfswg89kkc7yvfxg3a9z56q9pl7vfzzvqfcuaka8svut7p45shy2zuxv8c2";
  yubiserver = "age1yubikey1qwswvpt2rzs97gk5ktacd4xy0yr4rdls8uex2xpqvyrekdct74jkc0g0a4v";
in {
  "admin_password.age".publicKeys = [
    yubinano
    yubidev
    yubiserver
  ];
}
