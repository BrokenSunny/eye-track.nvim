local M = {}
local Label = require("eye-track.core.label")

--- @class EyeTrack.LabelSpec.Highlight
--- @field hl_group? string[] | fun(ctx: any): string[]
--- @field append_highlights? fun(any)[]

--- @class EyeTrack.LabelSpec
--- @field line integer
--- @field col integer
--- @field matched? fun(ctx: any)
--- @field highlight? EyeTrack.LabelSpec.Highlight
--- @field buf? integer
--- @field hidden_next_key? boolean
--- @field data? any

--- @class EyeTrack.Label.Config
--- @field unmatched?fun(ctx: any)
--- @field matched? fun(ctx: any)
--- @field position? fun(relative: integer, absolute: integer): integer
--- @field exclude? string[]
--- @field include? string[]
--- @field start? fun(ctx: any)
--- @field finish? fun(ctx: any)

--- @param labels EyeTrack.LabelSpec[]
--- @param config? EyeTrack.Label.Config
function M.main(labels, config)
  Label:new(labels, config):main()
end

return M
