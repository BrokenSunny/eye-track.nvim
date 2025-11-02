local Comment = vim.api.nvim_get_hl(0, { name = "Comment" })
vim.api.nvim_set_hl(0, "EyeTrackKeywordGeneralLayer", {
  fg = Comment.fg,
})

local function hightlight(topline, botline)
  local ns_id = vim.api.nvim_create_namespace("eye-track-keyword-general")
  vim.api.nvim_buf_set_extmark(0, ns_id, topline - 1, 0, {
    end_row = botline,
    hl_group = "EyeTrackKeywordGeneralLayer",
  })
  return function()
    vim.api.nvim_buf_clear_namespace(0, ns_id, topline - 1, botline)
  end
end

--- @param matches table<EyeTrack.Keyword.Match>
local function general_iter(matches, topline, botline, callback)
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  local count = 0
  local up_break = nil
  local down_break = nil
  while true do
    if count > 1000 then
      break
    end

    if up_break and down_break then
      break
    end

    if cursor_row - count >= topline then
      local match = matches[cursor_row - count - topline + 1]
      for _, value in ipairs(match) do
        local param = vim.tbl_extend("force", {
          line = cursor_row - count - 1,
        }, value)
        callback(param)
      end
    else
      up_break = true
    end

    if cursor_row + count < botline then
      local match = matches[cursor_row + count - topline + 2]
      for _, value in ipairs(match) do
        local param = vim.tbl_extend("force", {
          line = cursor_row + count,
        }, value)
        callback(param)
      end
    else
      down_break = true
    end

    count = count + 1
  end
end

local function main(opts)
  local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  local topline = wininfo.topline
  local botline = wininfo.botline
  ---@diagnostic disable-next-line: undefined-field
  local leftcol = wininfo.leftcol
  local rightcol = leftcol + wininfo.width - wininfo.textoff
  local matches = require("eye-track.keyword.core"):main({
    topline = topline,
    botline = botline,
    leftcol = leftcol,
    rightcol = rightcol,
    keyword = opts.keyword,
  })
  local registers = {}
  general_iter(matches, topline, botline, function(match)
    table.insert(registers, opts.create(match))
  end)
  local clear = hightlight(topline, botline)
  require("eye-track.core").main({
    reigsters = registers,
    unmatched = function()
      clear()
    end,
    matched = function()
      clear()
    end,
  })
end

return main
