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

--- @class EyeTrack.Plugin.Line.Matched.Context
--- @field row integer
--- @field col integer
--- @field label string
--- @field offset integer
--- @field topline integer
--- @field botline integer

--- @class EyeTrack.Plugin.Line.Config
--- @field range? fun(range: EyeTrack.Range): EyeTrack.Range
--- @field matched? fun(ctx: EyeTrack.Plugin.Line.Matched.Context)

--- @param config EyeTrack.Plugin.Line.Config
local function main(config)
  local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]

  local topline = wininfo.topline
  local botline = wininfo.botline
  if config.range and type(config.range) == "function" then
    local range = config.range({ topline = topline, botline = botline })
    topline = range[1]
    botline = range[2]
  end

  local virt_col = vim.fn.virtcol(".")
  local cursor = vim.api.nvim_win_get_cursor(0)

  --- @type EyeTrack.LabelSpec[]
  local labels = {}
  ---@diagnostic disable-next-line: undefined-field
  local virtualedit = vim.opt_local.virtualedit:get()[1]

  local callback
  if virtualedit == "all" then
    callback = function(row)
      ---@diagnostic disable-next-line: param-type-mismatch
      local _col = vim.fn.virtcol2col(vim.api.nvim_get_current_win(), row, virt_col) - 1
      if _col < 0 then
        _col = 0
      end
      local col = virt_col - wininfo.leftcol - 1
      labels[#labels + 1] = {
        virt = true,
        labels = {
          { row = row - 1, col = col },
        },
        data = {
          row = row,
          col = _col,
          offset = row - cursor[1],
          topline = topline,
          botline = botline,
        },
      }
    end
  elseif virtualedit == "none" then
    callback = function(row)
      local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
      ---@diagnostic disable-next-line: param-type-mismatch
      local _col = vim.fn.virtcol2col(vim.api.nvim_get_current_win(), row, virt_col) - 1
      if _col < 0 then
        _col = 0
      end
      local col = virt_col - 1
      if vim.fn.strdisplaywidth(line) < virt_col then
        col = vim.fn.strdisplaywidth(line) - 1
      end
      col = col - wininfo.leftcol
      if col < 0 then
        col = -1
      end
      labels[#labels + 1] = {
        virt = true,
        labels = {
          { row = row - 1, col = col },
        },
        data = {
          row = row,
          col = _col,
          offset = row - cursor[1],
          topline = topline,
          botline = botline,
        },
      }
    end
  end
  iter_line(cursor[1], topline, botline, callback)
  local Layer = require("eye-track.core.layer")
  require("eye-track.core").main(labels, {
    start = function()
      Layer.draw()
    end,
    finish = function()
      Layer.clear()
    end,
    matched = function(ctx)
      local context = ctx.data
      context.label = ctx.label
      config.matched(context)
    end,
  })
end

return main
