--- @class EyeTrack.Layer
local M = {}

--- @class EyeTrack.Layer.Highlight
--- @field start_pos [integer, integer]
--- @field end_pos [integer, integer]
--- @field hl_group string

--- @class EyeTrack.Layer.Config
--- @field enable? boolean
--- @field highlight? fun(ctx: any): EyeTrack.Layer.Highlight[]

local Comment = vim.api.nvim_get_hl(0, { name = "Comment" })
vim.api.nvim_set_hl(0, "EyeTrackLayer", {
  fg = Comment.fg,
})

--- @type EyeTrack.Layer.Config
local default_config = {
  enable = true,
  highlight = function()
    local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
    return {
      {
        hl_group = "EyeTrackLayer",
        start_pos = { wininfo.topline - 1, 0 },
        end_pos = { wininfo.botline, 0 },
      },
    }
  end,
}

local function hl(data)
  vim.api.nvim_buf_set_extmark(0, data.ns_id, data.start_pos[1], 0, {
    end_row = data.end_pos[1],
    hl_group = data.hl_group,
    hl_eol = true,
  })
end

--- @param config? EyeTrack.Layer.Config
function M.draw(config)
  config = vim.tbl_deep_extend("force", default_config, config or {})
  if not config.enable then
    return
  end
  if M.ns_id then
    return
  end
  M.ns_id = vim.api.nvim_create_namespace("eye-track-layer")
  local highlight = config.highlight
  if type(highlight) ~= "function" then
    return
  end
  for _, v in ipairs(highlight()) do
    v.ns_id = M.ns_id
    hl(v)
  end
end

function M.clear()
  if not M.ns_id then
    return
  end
  vim.api.nvim_buf_clear_namespace(0, M.ns_id, 0, -1)
  M.ns_id = nil
end

return M
