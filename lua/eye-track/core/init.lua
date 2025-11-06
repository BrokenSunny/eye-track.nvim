local M = {}

--- @class EyeTrack.LabelSpec.Highlight
--- @field hl_group? string[] | fun(ctx: any): string[]
--- @field append_highlights? fun(any)[]

--- @class EyeTrack.LabelSpec
--- @field line number
--- @field col number
--- @field matched? fun(ctx: any)
--- @field highlight? EyeTrack.LabelSpec.Highlight
--- @field buf? integer
--- @field data? any

--- @class EyeTrack.Label
--- @field position fun(relative: number, absolute: number): number

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
--- @field label? EyeTrack.Label
--- @field layer? EyeTrack.Layer

--- @param labels EyeTrack.LabelSpec[]
--- @param config? EyeTrack.Config
M.main = function(labels, config)
  require("eye-track.core.key"):main(labels, config)
end

return M
