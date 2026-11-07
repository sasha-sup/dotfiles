-- Cyberdeck for Neovim: the kitty palette mapped onto base16 slots, with the
-- syntax roles taken from vscode-theme/ so code reads the same in both editors.
-- mini.base16 does the bulk of the highlighting; the overrides below are only
-- what base16 cannot express.

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("cyberdeck: mini.base16 is not installed, run :Lazy sync", vim.log.levels.WARN)
  return
end

vim.o.background = "dark"

base16.setup({
  palette = {
    base00 = "#0e0e17", -- background
    base01 = "#161625", -- statusline, popups (kitty color0)
    base02 = "#172c2e", -- selection
    base03 = "#757575", -- comments (kitty color8)
    base04 = "#8b939b", -- dim UI text, between comments and body text
    base05 = "#c0c8cf", -- body text, variables
    base06 = "#e0e6eb",
    base07 = "#ffffff",
    base08 = "#ff6159", -- tags, headings
    base09 = "#c583ff", -- numbers, constants
    base0A = "#ffd741", -- types, classes
    base0B = "#1ded83", -- strings
    base0C = "#29ffb9", -- escapes, regex
    base0D = "#5ef6ff", -- functions
    base0E = "#ff6159", -- keywords
    base0F = "#ae3b36", -- operators, punctuation
  },
  use_cterm = true,
})
-- After setup: mini.base16 clears colors_name, and LazyVim reads it back.
vim.g.colors_name = "cyberdeck"

local hl = function(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

-- Transparent editor area: kitty draws the koi-lanterns wallpaper behind the
-- text, and a solid background here would cover it. Floats keep base01 so
-- completion menus stay readable over a busy image.
for _, group in ipairs({
  "Normal",
  "NormalNC",
  "SignColumn",
  "FoldColumn",
  "LineNr",
  "EndOfBuffer",
  "StatusLine",
  "StatusLineNC",
  "TabLineFill",
}) do
  local spec = vim.api.nvim_get_hl(0, { name = group, link = false })
  spec.bg = nil
  spec.ctermbg = nil
  hl(group, spec)
end

-- Matches editorLineNumber.* and lineHighlightBackground in the VS Code theme.
hl("LineNr", { fg = "#431618" })
hl("CursorLineNr", { fg = "#ff6159", bold = true })
hl("CursorLine", { bg = "#121221" })
hl("CursorLineSign", { bg = "#121221" })
hl("CursorLineFold", { bg = "#121221" })

-- variable.parameter in the VS Code theme
hl("@variable.parameter", { fg = "#ffb3ad" })
hl("@variable.builtin", { fg = "#ff7167" })
hl("@constant", { fg = "#ff7167" })
hl("@property", { fg = "#52dddf" })
hl("@punctuation.bracket", { fg = "#c0c8cf" })
