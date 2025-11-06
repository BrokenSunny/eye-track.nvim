local M = {}

function M:init()
  self.state = {
    children = {},
  }
end

function M:register(names, Key)
  names = vim.split(names, "")
  local state = self.state
  for _, name in ipairs(names) do
    if not state.children[name] then
      state.children[name] = {
        Key = Key,
        children = {},
      }
    end
    state = state.children[name]
  end
  return state
end

function M:query(names)
  names = vim.split(names, "")
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
