local function iter_line(cursor_row, topline, botline, callback)
  local top_break
  local bot_break
  local count = 0

  while true do
    count = count + 1
    if top_break and bot_break then
      break
    end

    if cursor_row - count >= topline then
      callback(cursor_row - count)
    else
      top_break = true
    end

    if cursor_row + count - 1 <= botline then
      callback(cursor_row + count - 1)
    else
      bot_break = true
    end
  end
end

local function main(options)
  local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  local topline = wininfo.topline
  local botline = wininfo.botline
  ---@diagnostic disable-next-line: undefined-field
  local leftcol = wininfo.leftcol
  local cursor = vim.api.nvim_win_get_cursor(0)

  local labels = {}
  iter_line(cursor[1], topline, botline, function(row)
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
    local label = {
      line = row - 1,
      data = {
        row = row,
      },
    }
    table.insert(labels, label)
    if options.position == -1 then
      local f = line:find("%S") or 1
      label.col = math.max(f - 1, 0)
    elseif options.position == -2 then
      label.col = 0
    elseif options.position == 0 then
    elseif options.position == 1 then
      local width = wininfo.width - wininfo.textoff
      local l = line:gsub("%s*$", "")
      label.col = math.min(#l - 1, leftcol + width - 1)
    elseif options.position == 2 then
      local width = wininfo.width - wininfo.textoff
      label.col = math.min(#line - 1, leftcol + width - 1)
    end
  end)
  local Layer = require("eye-track.core.layer")
  require("eye-track.core").main(labels, {
    start = function()
      Layer.draw()
    end,
    finish = function()
      Layer.clear()
    end,
    matched = options.matched,
  })
end

return main
