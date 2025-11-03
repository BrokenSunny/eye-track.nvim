local M = {}

--- @class EyeTrack.Core.Register
--- @field line number
--- @field virt_win_col number
--- @field data? any

--- @class EyeTrack.Core.Options
--- @field registers table<EyeTrack.Core.Register>
--- @field unmatched?fun(ctx: any)
--- @field matched? fun(ctx: any)

--- @class EyeTrack.Core.Active.Options
--- @field root any
--- @field matched? fun(ctx: any)
--- @field unmatched? fun(ctx: any)

vim.api.nvim_set_hl(0, "EyeTrackKey", {
  fg = "#ff007c",
  bold = true,
})
vim.api.nvim_set_hl(0, "EyeTrackNextKey", {
  fg = "#00dfff",
  bold = true,
})

--- @param options EyeTrack.Core.Options
M.main = function(options)
  require("eye-track.core.key"):main(options)
end

return M
