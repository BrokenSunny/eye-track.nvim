local M = {}
local Key = require("eye-track.core.key")

--- @class EyeTrack.LabelSpec.Highlight
--- @field hl_group? string[] | fun(ctx: any): string[]
--- @field append_highlights? fun(any)[]

--- @class EyeTrack.LabelSpec
--- @field line number
--- @field col number
--- @field matched? fun(ctx: any)
--- @field highlight? EyeTrack.LabelSpec.Highlight
--- @field buf? integer
--- @field hidden_next_key? boolean
--- @field data? any

--- @class EyeTrack.Label
--- @field position? fun(relative: number, absolute: number): number
--- @field exclude? string[]
--- @field include? string[]

--- @class EyeTrack.Layer.Highlight
--- @field start_pos [integer, integer]
--- @field end_pos [integer, integer]
--- @field hl_group string

--- @class EyeTrack.Layer
--- @field enable? boolean
--- @field highlight? fun(ctx: any): EyeTrack.Layer.Highlight[]

--- @class EyeTrack.Config
--- @field unmatched?fun(ctx: any)
--- @field matched? fun(ctx: any)
--- @field on_key? fun(ctx: any)
--- @field label? EyeTrack.Label
--- @field layer? EyeTrack.Layer

--- @param labels table<EyeTrack.LabelSpec>
--- @param config? EyeTrack.Config
function M.main(labels, config)
  Key:new(labels, config):main()
end

return M
