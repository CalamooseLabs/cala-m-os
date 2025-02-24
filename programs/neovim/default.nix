{ ... }:

{
  programs.neovim = {
    enable = true;
    extraConfig = ''
        set number relativenumber
        set tabstop=2
        set shiftwidth=2
        set expandtab
    '';
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
