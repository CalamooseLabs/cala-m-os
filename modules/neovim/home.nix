{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;

    plugins = with pkgs.vimPlugins; [
      nvim-web-devicons
      nvim-tree-lua
      plenary-nvim
      telescope-nvim
      bufferline-nvim
    ];

    extraLuaConfig = ''
      -- Your existing settings (converted to Lua)
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.expandtab = true
      vim.opt.termguicolors = true  -- needed for bufferline/icons
      vim.g.mapleader = " "         -- space as leader key

      -- Disable netrw (Neovim's built-in file browser)
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      -- nvim-tree (file tree)
      require("nvim-tree").setup({
        view = { width = 30 },
      })
      vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>", { silent = true })
      vim.keymap.set("n", "<leader>e", ":NvimTreeFocus<CR>", { silent = true })

      -- Telescope (fuzzy finder)
      require("telescope").setup()
      vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>", { silent = true })
      vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>", { silent = true })
      vim.keymap.set("n", "<leader>fb", ":Telescope buffers<CR>", { silent = true })

      -- Bufferline (buffer tabs)
      require("bufferline").setup({
        options = {
          offsets = {
            { filetype = "NvimTree", text = "Files", separator = true }
          },
        },
      })
      vim.keymap.set("n", "<Tab>", ":BufferLineCycleNext<CR>", { silent = true })
      vim.keymap.set("n", "<S-Tab>", ":BufferLineCyclePrev<CR>", { silent = true })
      vim.keymap.set("n", "<leader>x", ":bdelete<CR>", { silent = true })
    '';

    extraPackages = with pkgs; [
      ripgrep
      fd
    ];
  };

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Text Files
      "text/plain" = ["nvim.desktop"];
    };
  };
}
