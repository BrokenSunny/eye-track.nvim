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
      label.virt_win_col = f - leftcol - 1
      label.data.col = math.max(label.virt_win_col, 0)
    elseif options.position == -2 then
      label.virt_win_col = 0 - leftcol
      label.data.col = 0
    elseif options.position == 0 then
    elseif options.position == 1 then
      local width = wininfo.width - wininfo.textoff
      local l = line:gsub("%s*$", "")
      label.virt_win_col = math.min(#l - leftcol - 1, width - 1)
      label.data.col = #l
    elseif options.position == 2 then
      local width = wininfo.width - wininfo.textoff
      label.virt_win_col = math.min(vim.fn.strdisplaywidth(line) - leftcol - 1, width - 1)
      label.data.col = #line
    end
  end)
  require("eye-track.core").main(labels, {
    matched = options.matched,
  })
end

return main
