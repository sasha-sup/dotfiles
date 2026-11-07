-- The system palette lives in colors/cyberdeck.lua; this file only wires it in
-- and drops the two themes LazyVim installs by default.
return {
  { "nvim-mini/mini.base16", lazy = false, priority = 1000 },
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", name = "catppuccin", enabled = false },
  { "LazyVim/LazyVim", opts = { colorscheme = "cyberdeck" } },
}
