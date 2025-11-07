local function main(keyword)
  local wins = vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())
  local buflisteds = {}
  local wins_matches = {}
  for _, win in ipairs(wins) do
    local wininfo = vim.fn.getwininfo(win)[1]
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_get_option_value("buflisted", {
      buf = buf,
    }) and not buflisteds[tostring(buf)] then
      buflisteds[tostring(buf)] = true
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
        keyword = keyword,
      })
      table.insert(wins_matches, {
        win = win,
        buf = buf,
        matches = vim.tbl_deep_extend("force", {}, matches),
        topline = topline,
        botline = botline,
      })
    end
  end
  return wins_matches
end

return main
