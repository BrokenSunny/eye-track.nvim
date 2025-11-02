local M = {}

--- @class EyeTrack.Core.Register
--- @field callback fun()
--- @field line number
--- @field virt_win_col number
--- @field hidden_next_key? boolean | fun():boolean|nil

--- @class EyeTrack.Core.Options
--- @field reigsters table<EyeTrack.Core.Register>
--- @field unmatched?fun(any)
--- @field matched? fun(any)

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
