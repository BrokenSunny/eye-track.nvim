local M = {}

--- @class EyeTrackOption

--- @type fun(opts: EyeTrackOption)
function M.setup(opts)
  vim.api.nvim_set_hl(0, "EyeTrackKey", {
    fg = "#ff007c",
    bold = true,
  })
  vim.api.nvim_set_hl(0, "EyeTrackNextKey", {
    fg = "#00dfff",
    bold = true,
  })
end

return M
