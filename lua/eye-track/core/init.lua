local M = {}

--- @class EyeTrack.Core.Register
--- @field line number
--- @field virt_win_col number
--- @field matched? fun(ctx: any)
--- @field data? any

--- @class EyeTrack.Core.Label
--- @field position fun(relative: number, absolute: number): number

--- @class EyeTrack.Core.Layer.Highlight
--- @field start table<number>
--- @field _end table<number>
--- @field hl_group string

--- @class EyeTrack.Core.Layer
--- @field enable? boolean
--- @field highlight? fun(ctx: any): {[integer]: EyeTrack.Core.Layer.Highlight}

--- @class EyeTrack.Core.Options
--- @field registers table<EyeTrack.Core.Register>
--- @field unmatched?fun(ctx: any)
--- @field matched? fun(ctx: any)
--- @field label? EyeTrack.Core.Label
--- @field layer? EyeTrack.Core.Layer

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
