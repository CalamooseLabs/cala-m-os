{ pkgs, inputs, ... }:

{
    programs.bash = {
      enable = true;
      enableCompletion = true;
    };
}
