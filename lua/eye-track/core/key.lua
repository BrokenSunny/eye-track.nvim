local M = {}
local KEYS = "abcdefghijklmnopqrstuvwxyz"
local util = require("eye-track.core.util")

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
  for i, node in ipairs(ancestor_list) do
    if node then
      set_extmark({
        line = leaf.line,
        virt_win_col = leaf.virt_win_col + i - 1,
        ns_id = node.parent.ns_id,
        hl_group = i == 1 and "EyeTrackKey" or "EyeTrackNextKey",
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

--- @param options EyeTrack.Core.Active.Options
function M:active(options)
  table.insert(self.state, options.root)
  highlight_nodes(options.root)
  vim.cmd.redraw()
  self:listen(options)
end

function M:create_ns_id()
  local ns_id = vim.api.nvim_create_namespace("eye-track-namespace" .. #self.ns_ids)
  table.insert(self.ns_ids, ns_id)
  return ns_id
end

function M:clear_ns_id(opts)
  opts = opts or {}

  if opts.filter_id == nil then
    for _, ns_id in ipairs(self.ns_ids) do
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    end
    return
  end

  for _, ns_id in ipairs(self.ns_ids) do
    if ns_id ~= opts.filter_id then
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    end
  end
end

--- @param options EyeTrack.Core.Active.Options
function M:listen(options)
  local root = options.root
  local c = vim.fn.getchar()
  local key = vim.fn.keytrans(tostring(c)):lower()
  local char = vim.fn.nr2char(c --[[@as integer]])
  self:clear_ns_id()

  if key == "<bs>" or char == " " then
    local node = self.state[#self.state - 1]
    if node then
      self:active({
        root = node,
        unmatched = options.unmatched,
        matched = options.matched,
      })
      return
    end
  end

  if not root or root.children[char] == nil then
    util.callback_option(options.unmatched)
    return
  end

  local node = root.children[char]

  if node.level == 0 then
    util.callback_option(options.matched)
    node.callback()
  else
    self:active({
      root = node,
      matched = options.matched,
      unmatched = options.unmatched,
    })
  end
end

function M:register_leaf(parent, key, callback)
  if not key then
    return
  end
  local node = {
    level = 0,
    key = key,
    parent = parent,
    callback = function()
      util.callback_option(callback, key)
    end,
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

--- @param options EyeTrack.Core.Register
function M:_register(node, options)
  if not node then
    return
  end

  local function transfer()
    if node.parent then
      node.parent.current = nil
      self:_register(node.parent, options)
    end
  end

  if node.level == 1 then
    if node.remain == 0 then
      transfer()
      return
    end
    local leaf = self:register_leaf(node, get_random_key(node), options.matched)
    leaf.line = options.line
    leaf.virt_win_col = options.virt_win_col
    leaf.text = leaf.key
  else
    if node.current then
      self:_register(node.current, options)
      return
    end
    if node.remain == 0 then
      transfer()
      return
    end
    node.current = self:register_node(node, get_random_key(node))
    self:_register(node.current, options)
  end
end

--- @param options EyeTrack.Core.Register
function M:register(options)
  self:_register(self.root, options)
end

function M:init(total)
  local level, remain1, remain2 = compute(26, total)
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
  setmetatable(self.root.children, { __index = self.root.children["_"].children })
end

--- @param options EyeTrack.Core.Options
function M:main(options)
  local registers = options.reigsters
  self:init(#registers)
  for _, value in ipairs(registers) do
    self:register(value)
  end
  self:active({
    root = self.root,
    unmatched = options.unmatched,
    matched = options.matched,
  })
end

return M
