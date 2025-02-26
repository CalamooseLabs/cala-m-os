{ ... }:

{
  programs.qutebrowser = {
    enable = true;
    searchEngines = {
      k = "https://kagi.com/search?q={}";
      default = "https://kagi.com/search?q={}";
    };
  };
}
