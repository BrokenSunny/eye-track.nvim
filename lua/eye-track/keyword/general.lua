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
local function general_iter(win, matches, topline, botline, callback)
  local cursor_row = vim.api.nvim_win_get_cursor(win)[1]
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
  local wins = vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())
  local labels = {}
  for _, win in ipairs(wins) do
    local wininfo = vim.fn.getwininfo(win)[1]
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_get_option_value("buflisted", {
      buf = buf,
    }) then
      local topline = wininfo.topline
      local botline = wininfo.botline
      ---@diagnostic disable-next-line: undefined-field
      local leftcol = wininfo.leftcol
      local rightcol = leftcol + wininfo.width - wininfo.textoff
      local matches = require("eye-track.keyword.core"):main({
        buf = buf,
        topline = topline,
        botline = botline,
        leftcol = leftcol,
        rightcol = rightcol,
        keyword = opts.keyword,
      })
      matches = vim.tbl_deep_extend("force", {}, matches)
      general_iter(win, matches, topline, botline, function(match)
        local ctx = {
          match = match,
          hl_group1 = {
            "EyeTrackKeyword1",
            "EyeTrackKeywordKey1",
            "EyeTrackKeywordNextKey1",
          },
          hl_group2 = {
            "EyeTrackKeyword2",
            "EyeTrackKeywordKey2",
            "EyeTrackKeywordNextKey2",
          },
        }

        local hl_group
        if type(opts.hl_group) == "function" then
          hl_group = opts.hl_group(ctx)
        end
        if type(hl_group) ~= "table" then
          hl_group = nil
        end

        local data = vim.tbl_deep_extend("force", {}, match)
        data.win = win
        data.buf = buf
        local label = {
          buf = buf,
          data = data,
          line = match.line,
          highlight = {
            hl_group = hl_group and { hl_group[2], hl_group[3] },
            append_highlights = {
              function(ns_id)
                if not hl_group then
                  return
                end
                if type(hl_group[1]) ~= "string" then
                  return
                end
                vim.api.nvim_buf_set_extmark(buf, ns_id, match.line, match.start_virt_win_col, {
                  end_col = match.end_virt_win_col + 1,
                  hl_group = hl_group[1],
                })
              end,
            },
          },
        }
        if opts.label_position == "-1" then
          label.virt_win_col = match.start_virt_win_col
        elseif opts.label_position == "0" then
          label.virt_win_col = math.floor((match.end_virt_win_col - match.start_virt_win_col) / 2)
            + match.start_virt_win_col
        elseif opts.label_position == "1" then
          label.virt_win_col = match.end_virt_win_col
        end
        table.insert(labels, label)
      end)
    end
  end

  require("eye-track.core").main(labels, {
    matched = function(ctx)
      opts.matched(ctx)
    end,
  })
end

return main
