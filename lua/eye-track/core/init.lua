local M = {}
local Label = require("eye-track.core.label")

--- @class EyeTrack.Range
--- @field topline integer
--- @field botline integer

--- @class EyeTrack.LabelSpec.Highlight
--- @field group? string[] | fun(ctx: any): string[]
--- @field HighlightPre? fun(any)
--- @field HighlightPost? fun(any)

--- @class EyeTrack.LabelSpec.Label.Position
--- @field row integer
--- @field col integer

--- @class EyeTrack.LabelSpec.Label: EyeTrack.LabelSpec.Label.Position
--- @field virt? boolean
--- @field highlight? EyeTrack.LabelSpec.Highlight
--- @field hidden_next_key? boolean

--- @class EyeTrack.LabelSpec
--- @field labels EyeTrack.LabelSpec.Label[]
--- @field matched? fun(ctx: EyeTrack.Matched.Context)
--- @field buf? integer
--- @field virt? boolean
--- @field virt_text_pos? "eol" | "eol_right_align" | "overlay" | "right_align" | "inline"
--- @field highlight? EyeTrack.LabelSpec.Highlight
--- @field hidden_next_key? boolean
--- @field data? any

--- @class EyeTrack.Label.Config.Sublabel
--- @field relative_position? fun(relative: EyeTrack.LabelSpec.Label.Position, absolute: EyeTrack.LabelSpec.Label.Position): EyeTrack.LabelSpec.Label.Position

--- @class EyeTrack.Matched.Context
--- @field label string
--- @field labels EyeTrack.LabelSpec.Label[]
--- @field data any

--- @class EyeTrack.Label.Config
--- @field sublabel? EyeTrack.Label.Config.Sublabel
--- @field exclude? string[]
--- @field include? string[]
--- @field unmatched?fun(ctx: any)
--- @field matched? fun(ctx: EyeTrack.Matched.Context)
--- @field start? fun(ctx: any)
--- @field finish? fun(ctx: any)

--- @param labels EyeTrack.LabelSpec[]
--- @param config? EyeTrack.Label.Config
function M.main(labels, config)
  if #labels == 0 then
    return
  end
  M.refresh_highlights()
  Label:new(labels, config):main()
end

function M.refresh_highlights()
  vim.api.nvim_set_hl(0, "EyeTrackKey", {
    fg = "#ff007c",
    bold = true,
  })
  vim.api.nvim_set_hl(0, "EyeTrackNextKey", {
    fg = "#00dfff",
    bold = true,
  })
  vim.api.nvim_set_hl(0, "EyeTrackSearchIcon", {
    fg = "#ff007c",
    bold = true,
  })
end

return M
