local function iter_line(cursor_row, topline, botline, callback)
  local top_break
  local bot_break
  local count = 0

  while true do
    count = count + 1
    if bot_break and top_break then
      break
    end

    if cursor_row - count >= topline then
      callback(cursor_row - count)
    else
      top_break = true
    end

    if cursor_row + count <= botline then
      callback(cursor_row + count)
    else
      bot_break = true
    end
  end
end

local function main(options)
  local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  local topline = wininfo.topline
  local botline = wininfo.botline
  local virt_col = vim.fn.virtcol(".")
  local cursor = vim.api.nvim_win_get_cursor(0)

  --- @type EyeTrack.LabelSpec[]
  local labels = {}
  ---@diagnostic disable-next-line: undefined-field
  local virtualedit = vim.opt_local.virtualedit:get()[1]

  local callback
  if virtualedit == "all" then
    callback = function(row)
      table.insert(labels, {
        line = row - 1,
        col = virt_col - 1,
        data = {
          row = row,
          col = cursor[2],
        },
      })
    end
  elseif virtualedit == "none" then
    callback = function(row)
      local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
      local col
      local c
      if vim.fn.strdisplaywidth(line) < virt_col then
        col = #line - 1
        c = col + 1
      else
        col = virt_col - 1
        c = col
      end
      local label = {
        line = row - 1,
        col = col,
        data = {
          row = row,
          col = c,
        },
      }
      table.insert(labels, label)
    end
  end
  iter_line(cursor[1], topline, botline, callback)
  require("eye-track.core").main(labels, { matched = options.matched })
end

return main
