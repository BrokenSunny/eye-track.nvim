local M = {}

--- @class EyeTrack.Keyword.Options
--- @field keyword string | fun(BuiltinKeyword: table): string
--- @field topline number
--- @field botline number
--- @field leftcol number
--- @field rightcol number
--- @field should_capture? boolean
--- @field buf? integer

--- @class EyeTrack.Keyword.Match
--- @field start_col number
--- @field end_col number
--- @field start_virt_col number
--- @field end_virt_col number
--- @field start_virt_win_col number
--- @field end_virt_win_col number

local BUILTINKEYWORDMAP = {
  ["word_inner"] = "\\k\\+",
  ["word_outer"] = "\\k\\+\\s*",
  ["WORD_inner"] = "\\S\\+",
  ["WORD_outer"] = "\\S\\+\\s*",
}

local function get_pattern(pattern)
  if type(pattern) == "function" then
    pattern = pattern(BUILTINKEYWORDMAP)
    if type(pattern) ~= "string" then
      pattern = ""
    end
  else
    if type(pattern) ~= "string" then
      pattern = ""
    end
  end

  return pattern or ""
end

local function get_display_width(buf, start_row, start_col, end_row, end_col)
  local text = vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col, {})[1]
  local display_width = vim.fn.strdisplaywidth(text)
  return display_width
end

function M:match()
  for i = self.topline, self.botline do
    self:get_keyword(i, self.leftcol, self.rightcol)
  end
end

function M:collect_keyword(i, start_col, end_col, current_line)
  local start_virt_col = get_display_width(self.buf, i - 1, 0, i - 1, start_col)
  local end_virt_col = get_display_width(self.buf, i - 1, 0, i - 1, end_col) - 1

  --- @type EyeTrack.Keyword.Match
  local match = {
    start_col = start_col,
    end_col = end_col,
    start_virt_col = start_virt_col,
    end_virt_col = end_virt_col,
    start_virt_win_col = start_virt_col - self.leftcol,
    end_virt_win_col = end_virt_col - self.leftcol,
    row = i,
  }
  if self.should_capture then
    match.capture = current_line:sub(start_col + 1, end_col)
  end
  table.insert(self.matches[#self.matches], match)
end

function M:get_keyword(i, leftcol, rightcol)
  table.insert(self.matches, {})
  local start_pos = 0

  while true do
    local start, end_ = self.regex:match_line(self.buf, i - 1, start_pos)
    local current_line = self.should_capture and vim.api.nvim_buf_get_lines(self.buf, i - 1, i, false)[1]

    if not start or not end_ or (start == 0 and end_ == 0) then
      break
    end

    local start_col = start + start_pos
    local end_col = end_ + start_pos

    if end_col > leftcol then
      self:collect_keyword(i, start_col, end_col, current_line)
    end

    start_pos = start_pos + end_
  end
end

--- @param opts EyeTrack.Keyword.Options
function M:init(opts)
  self.topline = opts.topline
  self.botline = opts.botline
  self.leftcol = opts.leftcol
  self.rightcol = opts.rightcol

  --- @type table<EyeTrack.Keyword.Match>
  self.matches = {}
  self.buf = opts.buf or vim.api.nvim_get_current_buf()
  self.regex = vim.regex(get_pattern(opts.keyword))
end

--- @param opts EyeTrack.Keyword.Options
--- @return table<EyeTrack.Keyword.Match>
function M:main(opts)
  self:init(opts)
  self:match()
  return self.matches
end

return M
