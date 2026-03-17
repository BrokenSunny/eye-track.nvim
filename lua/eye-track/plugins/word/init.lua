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

--- @class EyeTrack.Plugin.Word.Context

--- @class EyeTrack.Plugin.Word.Label
--- @field position -1 | 0 | 1

--- @class EyeTrack.Plugin.Word.Options
--- @field keyword string | fun(BuiltinKeyword: table): string
--- @field range? fun(range: EyeTrack.Range): [integer, integer]
--- @field filter? fun(match: EyeTrack.Keyword.Match): boolean
--- @field matched fun(ctx: any)
--- @field unmatched? fun(ctx: any)
--- @field hl_group? string | fun(match: EyeTrack.Keyword.Match): string
--- @field condition? fun(matchs: EyeTrack.Keyword.Match[]): boolean
--- @field label EyeTrack.Plugin.Word.Label

--- @param opts EyeTrack.Plugin.Word.Options
local function main(opts)
  local labels = {}
  local data = require("eye-track.keyword.general")({
    keyword = opts.keyword,
    range = opts.range,
  })[1]
  local filter = type(opts.filter) == "function" and opts.filter or function()
    return false
  end
  local condition = type(opts.condition) == "function" and opts.condition or function()
    return true
  end

  if not condition(data.matches) then
    return
  end

  local win = data.win
  local buf = data.buf
  local matches = data.matches

  general_iter(win, matches, data.topline, data.botline, function(match)
    if filter(match) then
      return
    end
    local hl_group = opts.hl_group
    if type(hl_group) == "function" then
      hl_group = hl_group(match)
    end
    if type(hl_group) ~= "string" then
      hl_group = ""
    end
    local col
    if opts.label.position == -1 then
      col = match.start_col
    elseif opts.label.position == 0 then
      col = math.floor((match.end_col - 1 - match.start_col) / 2) + match.start_col
    elseif opts.label.position == 1 then
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

    if opts.label and type(opts.label) == "function" then
      label = opts.label(label)
    end

    table.insert(labels, label)
  end)

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
    unmatched = function(ctx)
      if type(opts.unmatched) == "function" then
        opts.unmatched(ctx)
      end
    end,
  })
end

return main
