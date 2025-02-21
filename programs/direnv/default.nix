{ pkgs, inputs, ... }:

{
    programs.direnv = {
        enable = true;
        enableBashIntegration = true;
    };
}
