local M = {}

--- @class EyeTrack.SearchState
--- @field children table<string, EyeTrack.SearchState>
--- @field Label EyeTrack.Label

function M:init()
  --- @type EyeTrack.SearchState
  ---@diagnostic disable-next-line: missing-fields
  self.state = {
    children = {},
  }
end

--- @param name string
--- @param Label EyeTrack.Label
--- @return EyeTrack.SearchState
function M:register(name, Label)
  local names = vim.split(name, "")
  --- @type EyeTrack.SearchState|nil
  local state = self.state
  for _, n in ipairs(names) do
    if not state.children[n] then
      state.children[n] = {
        Label = Label,
        children = {},
      }
    end
    state = state.children[n]
  end

  return state
end

--- @return EyeTrack.SearchState|nil
function M:query(names)
  names = vim.split(names, "")
  --- @type EyeTrack.SearchState|nil
  local state = self.state
  for _, name in ipairs(names) do
    if state and state.children[name] then
      state = state.children[name]
    else
      state = nil
    end
  end

  return state
end

return M
