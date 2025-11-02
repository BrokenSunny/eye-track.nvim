local function main(options)
  local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  local topline = wininfo.topline
  local botline = wininfo.botline
  ---@diagnostic disable-next-line: undefined-field
  local leftcol = wininfo.leftcol
  local virt_win_col = vim.fn.virtcol(".") - leftcol - 1
  local cursor = vim.api.nvim_win_get_cursor(0)

  local registers = {}
  for i = topline, botline do
    if i ~= cursor[1] then
      table.insert(registers, {
        line = i - 1,
        virt_win_col = virt_win_col,
        callback = function()
          options.callback({
            offset = cursor[1] - i,
            row = i,
            col = cursor[2],
          })
        end,
      })
    end
  end
  require("eye-track.core").main({ reigsters = registers })
end

return main
