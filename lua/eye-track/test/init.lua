local M = {}

function M.main()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  local wininfo = vim.fn.getwininfo(win)[1]
  local topline = wininfo.topline
  local botline = wininfo.botline
  ---@diagnostic disable-next-line: undefined-field
  local leftcol = wininfo.leftcol
  local rightcol = leftcol + wininfo.width - wininfo.textoff

  local function step(base)
    local labels = {}
    local exclude = {}
    if base ~= "" then
      local matches = require("eye-track.keyword.core"):main({
        buf = buf,
        topline = topline,
        botline = botline,
        leftcol = leftcol,
        rightcol = rightcol,
        keyword = base .. ".",
      })
      for _, value in ipairs(matches) do
        for _, match in ipairs(value) do
          local text =
            vim.api.nvim_buf_get_text(buf, match.row - 1, match.start_col, match.row - 1, match.end_col, {})[1]
          local last_char = vim.fn.strcharpart(text, vim.fn.strcharlen(text) - 1, 1)
          table.insert(exclude, last_char)
          local label = {
            buf = buf,
            line = match.row - 1,
            col = match.end_col - #last_char,
            data = match,
            highlight = {
              append_highlights = {
                function(ns_id)
                  vim.api.nvim_buf_set_extmark(buf, ns_id, match.row - 1, match.start_col, {
                    end_col = match.end_col - #last_char,
                    hl_group = "Visual",
                  })
                end,
              },
            },
          }
          table.insert(labels, label)
        end
      end
    end
    require("eye-track.core").main(labels, {
      label = {
        exclude = exclude,
      },
      on_key = function(ctx)
        if ctx.matched then
          vim.api.nvim_win_set_cursor(0, { ctx.line + 1, ctx.data.start_col })
          return
        end
        if ctx.label == "<esc>" then
          return
        end
        local next_pattern
        if ctx.label == "<bs>" then
          next_pattern = vim.fn.strcharpart(base, 0, vim.fn.strcharlen(base) - 1)
        else
          next_pattern = base .. ctx.label
        end
        vim.notify(next_pattern)
        step(next_pattern)
      end,
    })
  end

  step("")
end

return M
