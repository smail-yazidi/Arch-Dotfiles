-- ==============================
-- Basic UI Settings
-- ==============================

vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.g.mapleader = " "

-- Disable swapfile warnings
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.clipboard = "unnamedplus"

-- GUI Font (for GUI clients like Neovide, NVim-Qt)
vim.opt.guifont = "FiraCode Nerd Font:h20"

-- ==============================
-- Package Manager: lazy.nvim
-- ==============================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

  -- Colorscheme: Tokyonight
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({})
      vim.cmd("colorscheme tokyonight")
      vim.cmd("highlight Normal guibg=#000818")
      vim.cmd("highlight NormalNC guibg=#000818")
      vim.cmd("highlight NvimTreeNormal guibg=#000818")
      vim.cmd("highlight NvimTreeNormalNC guibg=#000818")
      vim.cmd("highlight TelescopeNormal guibg=#000818")
      vim.cmd("highlight TelescopeBorder guibg=#000818 guifg=#FFFFFF")
      vim.cmd("highlight TelescopePromptNormal guibg=#000818")
      vim.cmd("highlight TelescopePromptBorder guibg=#000818 guifg=#FFFFFF")
      vim.cmd("highlight TelescopePreviewNormal guibg=#000818")
      vim.cmd("highlight TelescopePreviewBorder guibg=#000818 guifg=#FFFFFF")
    end
  },

  -- Treesitter
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

  -- LSP (JavaScript/TypeScript, Python, Java)
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      vim.diagnostic.config({
        virtual_text = {
          prefix = "•",
          source = "always",
          severity = {
            min = vim.diagnostic.severity.HINT,
            max = vim.diagnostic.severity.ERROR
          }
        },
        signs = false,
        update_in_insert = true,
        float = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      })
      lspconfig.ts_ls.setup {}
      lspconfig.pyright.setup {}
      lspconfig.jdtls.setup {}
    end
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip"
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end
        },
        mapping = {
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" }
        })
      })
    end
  },

  -- Lualine: Statusline with full path, file state, time
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight",
          section_separators = "",
          component_separators = "",
          globalstatus = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = { "filename" },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location", function() return os.date("%H:%M") end },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {}
        },
      })
    end
  },

  -- Autosave
  { "Pocco81/auto-save.nvim", config = function() require("auto-save").setup() end },

  -- File Explorer: Nvim-Tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
    end
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      vim.keymap.set("n", "<leader>f", ":Telescope find_files<CR>", { noremap = true, silent = true })
    end
  },

  -- Toggle Terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup()
      vim.keymap.set("n", "<leader>t", ":ToggleTerm<CR>", { noremap = true, silent = true })
    end
  },

})

-- Corrected and consolidated a CursorHold autocommand and Treesitter setup outside of lazy.nvim
vim.api.nvim_create_autocmd("CursorHold", {
  group = vim.api.nvim_create_augroup("MyLspCursorHold", { clear = true }),
  callback = function()
    vim.diagnostic.open_float({
      severity = { min = vim.diagnostic.severity.HINT },
      focusable = false,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
      scope = "line",
    })
  end,
})
-- Add this line to set the background color of the floating window
vim.cmd("highlight NormalFloat guibg=#000818")

-- Add this line to set the background color of the floating window's border
vim.cmd("highlight FloatBorder guibg=#000818")
-- Add this line to set the background color of the floating window
vim.cmd("highlight NormalFloat guibg=#000818")-- Treesitter Setup
require("nvim-treesitter.configs").setup {
  highlight = { enable = true },
  ensure_installed = { "javascript", "typescript", "lua", "html", "css", "python", "java" }
}
