local M = {}
local Label = require("eye-track.core.label")

--- @class EyeTrack.Range
--- @field topline integer
--- @field botline integer

--- @class EyeTrack.LabelSpec.Highlight
--- @field hl_group? string[] | fun(ctx: any): string[]
--- @field append_highlights? fun(any)[]

--- @class EyeTrack.LabelSpec
--- @field line integer
--- @field col integer
--- @field virt? boolean
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
