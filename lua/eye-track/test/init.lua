local M = {}
local State = require("eye-track.test.state")

local function rollback_state(pattern)
  local state = State:query(pattern)
  if state and state.Key then
    vim.notify(pattern)
    state.Key:active(state.Key.root)
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
  for _, value in ipairs(matches) do
    for _, match in ipairs(value) do
      callback(match)
    end
  end
end

function M.main()
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
    local label = {
      buf = buf,
      line = match.row - 1,
      col = match.end_col - offset,
      data = match,
      highlight = {
        append_highlights = {
          function(ns_id)
            vim.api.nvim_buf_set_extmark(buf, ns_id, match.row - 1, match.start_col, {
              end_col = match.end_col - offset,
              hl_group = "Visual",
            })
          end,
        },
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

  local function step(pattern)
    local exclude = {}
    local labels = create_labels(pattern, exclude)
    local Key = require("eye-track.core.key"):new(labels, {
      label = { exclude = exclude },
      on_key = function(ctx)
        if ctx.matched then
          vim.api.nvim_win_set_cursor(0, { ctx.line + 1, ctx.data.start_col })
          return
        end
        if ctx.label:lower() == "<esc>" then
          return
        end
        local next_pattern
        if ctx.label:lower() == "<bs>" then
          next_pattern = vim.fn.strcharpart(pattern, 0, vim.fn.strcharlen(pattern) - 1)
        else
          local label = ctx.label:lower() == "<space>" and " " or ctx.label
          next_pattern = pattern .. label
        end
        if rollback_state(next_pattern) then
          return
        end
        vim.notify(next_pattern)
        step(next_pattern)
      end,
    })
    State:register(pattern, Key)
    Key:main()
  end
  step("")
end

return M
