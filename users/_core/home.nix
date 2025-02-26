{ username, user_home_path, ... }: { ... }:

{
  home = {
    username = "${username}";
    homeDirectory = "${user_home_path}";
  };
}
