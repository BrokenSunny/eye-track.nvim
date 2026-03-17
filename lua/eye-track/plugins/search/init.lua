local State = require("eye-track.plugins.search.state")

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

local function notify(msg)
  vim.api.nvim_echo({
    { "󰐰 ", "EyeTrackSearchIcon" },
    { msg, "WarningMsg" },
  }, false, {})
end

local function rollback_state(pattern)
  local state = State:query(pattern)
  if state and state.Label then
    notify(pattern)
    state.Label:active()
    return true
  end
end

local function match_text(buf, topline, botline, leftcol, rightcol, pattern, callback)
  local matches = require("eye-track.keyword.core"):main({
    buf = buf,
    topline = topline,
    botline = botline,
    leftcol = leftcol,
    rightcol = rightcol,
    keyword = pattern:gsub("([\\^$.~[*?+])", "\\%1") .. ".\\?",
  })
  general_iter(0, matches, topline, botline, callback)
end

--- @class EyeTrack.Plugin.Search.MatchContext: EyeTrack.Keyword.Match
--- @field label string

--- @class EyeTrack.Plugin.Search.Config
--- @field matched fun(ctx: EyeTrack.Plugin.Search.MatchContext)
--- @field unmatched fun(ctx: EyeTrack.Plugin.Search.MatchContext)

--- @param config EyeTrack.Plugin.Search.Config
local function main(config)
  require("eye-track.core").refresh_highlights()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  local wininfo = vim.fn.getwininfo(win)[1]
  local topline = wininfo.topline
  local botline = wininfo.botline
  ---@diagnostic disable-next-line: undefined-field
  local leftcol = wininfo.leftcol
  local rightcol = leftcol + wininfo.width - wininfo.textoff
  State:init()

  local function get_label(match, pattern, exclude)
    local text = vim.api.nvim_buf_get_text(buf, match.row - 1, match.start_col, match.row - 1, match.end_col, {})[1]
    local offset = 0
    if #text > #pattern then
      local last_char = vim.fn.strcharpart(text, vim.fn.strcharlen(text) - 1, 1)
      table.insert(exclude, last_char)
      offset = #last_char
    end
    ---@type EyeTrack.LabelSpec
    local label = {
      buf = buf,
      labels = {
        { row = match.row - 1, col = match.end_col - offset },
      },
      data = vim.tbl_deep_extend("force", match, {
        end_col = match.end_col - offset - 1,
      }),
      highlight = {
        HighlightPre = function(ns_id)
          vim.api.nvim_buf_set_extmark(buf, ns_id, match.row - 1, match.start_col, {
            end_col = match.end_col - offset,
            hl_group = "Visual",
          })
        end,
      },
    }
    return label
  end

  local function create_labels(pattern, exclude)
    local labels = {}
    if pattern ~= "" then
      match_text(buf, topline, botline, leftcol, rightcol, pattern, function(match)
        table.insert(labels, get_label(match, pattern, exclude))
      end)
    end
    return labels
  end

  local Layer = require("eye-track.core.layer")

  local function step(pattern)
    local exclude = {}
    local labels = create_labels(pattern, exclude)
    local Label = require("eye-track.core.label"):new(labels, {
      exclude = exclude,
      start = function()
        Layer.draw()
      end,
      finish = function(ctx)
        if ctx.matched then
          local context = ctx.data
          context.label = context.label
          config.matched(context)
          Layer.clear()
          return
        end
        if ctx.label:lower() == "<esc>" then
          if type(config.unmatched) == "function" then
            config.unmatched(ctx)
          end
          Layer.clear()
          return
        end
        local next_pattern
        if ctx.label:lower() == "<bs>" then
          next_pattern = vim.fn.strcharpart(pattern, 0, vim.fn.strcharlen(pattern) - 1)
        elseif ctx.label:lower() == "<cr>" then
          next_pattern = pattern
        else
          local label = ctx.label:lower() == "<space>" and " " or ctx.label
          next_pattern = pattern .. label
        end
        if rollback_state(next_pattern) then
          return
        end
        notify(next_pattern)
        step(next_pattern)
      end,
    })
    State:register(pattern, Label)
    Label:main()
  end
  step("")
end

return main
