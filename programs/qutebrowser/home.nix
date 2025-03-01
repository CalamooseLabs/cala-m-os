{ ... }:

{
  programs.qutebrowser = {
    enable = true;
    searchEngines = {
      k = "https://kagi.com/search?q={}";
      DEFAULT = "https://kagi.com/search?q={}";
    };
  };
}
