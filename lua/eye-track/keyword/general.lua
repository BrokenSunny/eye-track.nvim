local EyeTrackKey = vim.api.nvim_get_hl(0, {
  name = "EyeTrackKey",
})
local EyeTrackNextKey = vim.api.nvim_get_hl(0, {
  name = "EyeTrackNextKey",
})
vim.api.nvim_set_hl(0, "EyeTrackKeyword1", {
  bg = "#cccccc",
})
vim.api.nvim_set_hl(0, "EyeTrackKeywordKey1", {
  bg = "#cccccc",
  fg = EyeTrackKey.fg,
})
vim.api.nvim_set_hl(0, "EyeTrackKeywordNextKey1", {
  bg = "#cccccc",
  fg = EyeTrackNextKey.fg,
})

vim.api.nvim_set_hl(0, "EyeTrackKeyword2", {
  bg = "#aaaaaa",
})
vim.api.nvim_set_hl(0, "EyeTrackKeywordKey2", {
  bg = "#aaaaaa",
  fg = EyeTrackKey.fg,
})
vim.api.nvim_set_hl(0, "EyeTrackKeywordNextKey2", {
  bg = "#aaaaaa",
  fg = EyeTrackNextKey.fg,
})
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
  local labels = {}
  general_iter(matches, topline, botline, function(match)
    local ctx = {
      match = match,
      hl_groups = {
        EyeTrackKeyword1 = "EyeTrackKeyword1",
        EyeTrackKeywordKey1 = "EyeTrackKeywordKey1",
        EyeTrackKeywordNextKey1 = "EyeTrackKeywordNextKey1",
        EyeTrackKeyword2 = "EyeTrackKeyword2",
        EyeTrackKeywordKey2 = "EyeTrackKeywordKey2",
        EyeTrackKeywordNextKey2 = "EyeTrackKeywordNextKey2",
      },
      create_highlight = function(options)
        return {
          hl_group = options.label,
          append_highlights = {
            function(ns_id)
              vim.api.nvim_buf_set_extmark(0, ns_id, match.line, match.start_virt_win_col, {
                end_col = match.end_virt_win_col + 1,
                hl_group = options.keyword,
              })
            end,
          },
        }
      end,
    }
    local label = opts.create_label(ctx)
    label.data = match
    table.insert(labels, label)
  end)
  require("eye-track.core").main(labels, {
    matched = function(ctx)
      opts.matched(ctx)
    end,
  })
end

return main
