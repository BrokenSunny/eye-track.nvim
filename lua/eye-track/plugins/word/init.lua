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
        callback(value)
      end
    else
      up_break = true
    end

    if cursor_row + count < botline then
      local match = matches[cursor_row + count - topline + 2]
      for _, value in ipairs(match) do
        callback(value)
      end
    else
      down_break = true
    end

    count = count + 1
  end
end

local function main(opts)
  local labels = {}
  local current_tabpage_matches = require("eye-track.keyword.general")(opts.keyword)

  for _, data in ipairs(current_tabpage_matches) do
    local win = data.win
    local buf = data.buf
    local matches = data.matches
    general_iter(win, matches, data.topline, data.botline, function(match)
      local ctx = {
        match = match,
      }
      local hl_group = opts.hl_group
      if type(hl_group) == "function" then
        hl_group = hl_group(ctx)
      end
      if type(hl_group) ~= "string" then
        hl_group = ""
      end
      local col
      if opts.label_position == "-1" then
        col = match.start_col
      elseif opts.label_position == "0" then
        col = math.floor((match.end_col - 1 - match.start_col) / 2) + match.start_col
      elseif opts.label_position == "1" then
        col = match.end_col - 1
      end
      local label = {
        buf = buf,
        line = match.row - 1,
        col = col,
        data = vim.tbl_deep_extend("force", {
          win = win,
          buf = buf,
        }, match),
        hidden_next_key = (match.end_col - match.start_col) == 1,
        highlight = {
          append_highlights = {
            function(ns_id)
              if hl_group == "" then
                return
              end
              vim.api.nvim_buf_set_extmark(buf, ns_id, match.row - 1, match.start_col, {
                end_col = match.end_col,
                hl_group = hl_group,
              })
            end,
          },
        },
      }
      table.insert(labels, label)
    end)
  end
  local Layer = require("eye-track.core.layer")
  require("eye-track.core").main(labels, {
    start = function()
      Layer.draw()
    end,
    finish = function()
      Layer.clear()
    end,
    matched = function(ctx)
      opts.matched(ctx)
    end,
  })
end

return main
