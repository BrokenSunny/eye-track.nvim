local M = {}

--- @class EyeTrack.Core.LabelSpec.Highlight
--- @field hl_group? string[] | fun(ctx: any): string[]
--- @field append_highlights? fun(any)[]

--- @class EyeTrack.Core.LabelSpec
--- @field line number
--- @field col number
--- @field matched? fun(ctx: any)
--- @field highlight? EyeTrack.Core.LabelSpec.Highlight
--- @field buf? integer
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
--- @field unmatched?fun(ctx: any)
--- @field matched? fun(ctx: any)
--- @field label? EyeTrack.Core.Label
--- @field layer? EyeTrack.Core.Layer

--- @param labels EyeTrack.Core.LabelSpec[]
--- @param options? EyeTrack.Core.Options
M.main = function(labels, options)
  require("eye-track.core.key"):main(labels, options)
end

return M
