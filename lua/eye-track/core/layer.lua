local M = {}

local Comment = vim.api.nvim_get_hl(0, { name = "Comment" })
vim.api.nvim_set_hl(0, "EyeTrackLayer", {
  fg = Comment.fg,
})

--- @type EyeTrack.Core.Layer
local default = {
  enable = true,
  highlight = function()
    local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
    return {
      {
        hl_group = "EyeTrackLayer",
        start = { wininfo.topline - 1, 0 },
        _end = { wininfo.botline, 0 },
      },
    }
  end,
}

local function hl(data)
  vim.api.nvim_buf_set_extmark(0, data.ns_id, data.start[1], 0, {
    end_row = data._end[1],
    hl_group = data.hl_group,
    hl_eol = true,
  })
end

function M:draw()
  if not self.config.enable then
    return
  end
  local highlight = self.config.highlight
  if type(highlight) ~= "function" then
    return
  end
  for _, v in ipairs(highlight()) do
    v.ns_id = self.ns_id
    hl(v)
  end
end

function M:clear()
  if self.ns_id ~= nil then
    vim.api.nvim_buf_clear_namespace(0, self.ns_id, 0, -1)
    self.ns_id = nil
  end
end

--- @type fun(config?: EyeTrack.Core.Layer, callback: any)
function M.access(config, callback)
  M.config = vim.tbl_deep_extend("force", default, config or {})
  if not M.config.enable then
    return
  end
  callback(function()
    M:draw()
  end, function()
    M:clear()
  end)
  M.ns_id = vim.api.nvim_create_namespace("eye-track-layer")
end

return M
