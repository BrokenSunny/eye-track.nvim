local M = {}
local KEYS = "abcdefghijklmnopqrstuvwxyz"
local util = require("eye-track.core.util")

local default_config = {
  label = {
    position = function(relative, absolute)
      return relative + 1
    end,
  },
}

local function get_leaf_ancestor_list(leaf, root)
  local ancestor_list = {}
  local node = leaf
  while node do
    if node.key then
      table.insert(ancestor_list, 1, node)
    end
    node = node.parent
    if node.ns_id == root.ns_id and node.key == root.key then
      node = nil
    end
  end
  return ancestor_list
end

local function set_extmark(options)
  local line = options.line
  local virt_win_col = options.virt_win_col
  local ns_id = options.ns_id
  vim.api.nvim_buf_set_extmark(0, ns_id, line, 0, {
    virt_text_win_col = virt_win_col,
    virt_text = { { options.text, options.hl_group } },
  })
end

local function highlight_node(leaf, root)
  local ancestor_list = get_leaf_ancestor_list(leaf, root)
  local relative_postion = leaf.data.virt_win_col - 1

  local highlight = leaf.highlight
  if type(highlight.hl_group) == "function" then
    highlight.hl_group = highlight.hl_group({})
  end
  if type(highlight.hl_group) ~= "table" then
    highlight.hl_group = { "EyeTrackKey", "EyeTrackNextKey" }
  end

  for i, node in ipairs(ancestor_list) do
    if node then
      if node.level == 0 then
        if type(highlight.append_highlights) == "table" then
          for _, cb in ipairs(highlight.append_highlights) do
            util.callback_option(cb, node.parent.ns_id)
          end
        end
      end
      local virt_win_col = M.config.label.position(relative_postion, leaf.data.virt_win_col)
      relative_postion = virt_win_col
      set_extmark({
        line = leaf.data.line,
        virt_win_col = virt_win_col,
        ns_id = node.parent.ns_id,
        hl_group = highlight.hl_group[i] or highlight.hl_group[#highlight.hl_group],
        text = node.key,
      })
    end
  end
end

local function highlight_nodes(root)
  local function run(node)
    if node.level == 0 then
      highlight_node(node, root)
      return
    end
    for _, child in pairs(node.children or {}) do
      run(child)
    end
  end
  run(root)
end

local function get_random_key(node)
  if node.remain == 0 then
    return
  end

  local random = math.random(26)
  local key = KEYS:sub(random, random)
  if node.children[key] == nil then
    return key
  end

  return get_random_key(node)
end

--- @return number
--- @return number
--- @return number
local function compute(label_count, total)
  --- @return number
  --- @return number
  --- @return number
  local function compute_run(i)
    local min = label_count * math.pow(26, i - 1)
    local max = label_count * math.pow(26, i)

    if total >= min and total <= max then
      local remain = total - min
      local quotient = math.ceil(remain / min)
      local remainder = remain - (quotient * min)
      local key_count = math.ceil((remainder + quotient) / min) + quotient
      return i, label_count - key_count, key_count
    elseif total > max then
      return compute_run(i + 1)
    end
    return i, total, 0
  end

  return compute_run(1)
end

function M:active(root)
  table.insert(self.state, root)
  highlight_nodes(root)
  vim.cmd.redraw()
  self:listen(root)
end

function M:create_ns_id()
  local ns_id = vim.api.nvim_create_namespace("eye-track-namespace" .. #self.ns_ids)
  table.insert(self.ns_ids, ns_id)
  return ns_id
end

function M:clear_ns_id()
  for _, ns_id in ipairs(self.ns_ids) do
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  end
end

function M:listen(root)
  local c = vim.fn.getchar()
  local key = vim.fn.keytrans(tostring(c)):lower()
  local char = vim.fn.nr2char(c --[[@as integer]])
  self:clear_ns_id()

  if key == "<bs>" or char == " " then
    local node = self.state[#self.state - 1]
    if node then
      self:active(node)
      return
    end
  end

  if not root or root.children[char] == nil then
    util.callback_option(self.config.unmatched)
    self:finish()
    return
  end

  local node = root.children[char]

  if node.level == 0 then
    util.callback_option(node.matched and node.matched or self.config.matched, node.data)
    self:finish()
  else
    self:active(node)
  end
end

function M:register_leaf(parent, key)
  if not key then
    return
  end
  local node = {
    level = 0,
    key = key,
    parent = parent,
  }
  parent.children[key] = node
  parent.remain = parent.remain - 1
  return node
end

function M:register_node(parent, key)
  if not key then
    return
  end
  local node = {
    level = parent.level - 1,
    key = key,
    parent = parent,
    remain = 26,
    children = {},
    ns_id = self:create_ns_id(),
  }
  parent.children[key] = node
  parent.remain = parent.remain - 1
  return node
end

--- @param label EyeTrack.Core.LabelSpec
function M:_register(node, label)
  if not node then
    return
  end

  local function transfer()
    if node.parent then
      node.parent.current = nil
      self:_register(node.parent, label)
    end
  end

  if node.level == 1 then
    if node.remain == 0 then
      transfer()
      return
    end
    local leaf = self:register_leaf(node, get_random_key(node))
    leaf.matched = label.matched
    leaf.highlight = label.highlight or {}
    leaf.data = {
      line = label.line,
      virt_win_col = label.virt_win_col,
      key = leaf.key,
      data = label.data,
    }
  else
    if node.current then
      self:_register(node.current, label)
      return
    end
    if node.remain == 0 then
      transfer()
      return
    end
    node.current = self:register_node(node, get_random_key(node))
    self:_register(node.current, label)
  end
end

--- @param options EyeTrack.Core.LabelSpec
function M:register(options)
  self:_register(self.root, options)
end

--- @param total number
--- @param options? EyeTrack.Core.Options
function M:init(total, options)
  options = options or {}
  local level, remain1, remain2 = compute(26, total)
  self.config = {
    matched = options.matched,
    unmatched = options.unmatched,
    label = vim.tbl_deep_extend("force", default_config.label, options.label or {}),
  }
  self.state = {}
  self.ns_ids = {}
  self.root = {
    level = level + 1,
    remain = remain2 + 1,
    children = {},
    ns_id = self:create_ns_id(),
  }
  self.root.current = self:register_node(self.root, "_")
  self.root.current.key = nil
  self.root.current.remain = remain1
  self.finish_callbacks = {}
  self.begin_callbacks = {}
  setmetatable(self.root.children, { __index = self.root.children["_"].children })
  require("eye-track.core.layer").access(options.layer, function(begin, finish)
    table.insert(self.begin_callbacks, begin)
    table.insert(self.finish_callbacks, finish)
  end)
end

--- @param labels table<EyeTrack.Core.LabelSpec>
--- @param options? EyeTrack.Core.Options
function M:main(labels, options)
  self:init(#labels, options)
  for _, label in ipairs(labels) do
    self:register(label)
  end
  self:begin()
  self:active(self.root)
end

function M:finish()
  for _, cb in ipairs(self.finish_callbacks) do
    cb()
  end
end

function M:begin()
  for _, cb in ipairs(self.begin_callbacks) do
    cb()
  end
end

return M
