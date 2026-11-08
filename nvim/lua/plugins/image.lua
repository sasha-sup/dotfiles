-- Show images inside Neovim instead of their bytes. snacks.image draws them through
-- kitty's graphics protocol; ImageMagick converts anything kitty cannot read natively.
return {
  "folke/snacks.nvim",
  opts = {
    image = { enabled = true },
  },
}
