--- @class EyeTrack.Key
local M = {}
local util = require("eye-track.core.util")

local default_config = {
  label = {
    position = function(relative, absolute)
      return relative + 1
    end,
    exclude = {},
    include = {
      "a",
      "b",
      "c",
      "d",
      "e",
      "f",
      "g",
      "h",
      "i",
      "j",
      "k",
      "l",
      "m",
      "n",
      "o",
      "p",
      "q",
      "r",
      "s",
      "t",
      "u",
      "v",
      "w",
      "x",
      "y",
      "z",
    },
  },
}

local function finish(self)
  for _, cb in ipairs(self.finish_callbacks) do
    cb()
  end
end

local function begin(self)
  for _, cb in ipairs(self.begin_callbacks) do
    cb()
  end
end

local function get_leaf_ancestor_list(leaf, root)
  local ancestor_list = { leaf }
  local node = leaf.parent
  while node do
    if node.id == root.id then
      break
    end
    if node.label then
      table.insert(ancestor_list, 1, node)
    end
    node = node.parent
  end
  return ancestor_list
end

local function set_extmark(options)
  local line = options.line
  local col = options.col
  local ns_id = options.ns_id
  pcall(vim.api.nvim_buf_set_extmark, options.buf, ns_id, line, col, {
    virt_text_pos = "overlay",
    virt_text = { { options.text, options.hl_group } },
    end_col = col,
    hl_mode = "combine",
  })
end

local function highlight_node(self, leaf, root)
  local ancestor_list = get_leaf_ancestor_list(leaf, root)
  local relative_postion = leaf.data.col - 1

  local highlight = leaf.highlight
  if type(highlight.hl_group) == "function" then
    highlight.hl_group = highlight.hl_group({})
  end
  if type(highlight.hl_group) ~= "table" then
    highlight.hl_group = { "EyeTrackKey", "EyeTrackNextKey" }
  end

  local function hl(i, node)
    if node.level == 0 then
      if type(highlight.append_highlights) == "table" then
        for _, cb in ipairs(highlight.append_highlights) do
          util.callback_option(cb, self.ns_id)
        end
      end
    end
    if leaf.hidden_next_key and i ~= 1 then
      return
    end
    local col = self.config.label.position(relative_postion, leaf.data.col)
    relative_postion = col
    set_extmark({
      buf = leaf.data.buf,
      line = leaf.data.line,
      col = col,
      ns_id = self.ns_id,
      hl_group = highlight.hl_group[i] or highlight.hl_group[#highlight.hl_group],
      text = node.label,
    })
  end

  for i, node in ipairs(ancestor_list) do
    hl(i, node)
  end
end

local function highlight_nodes(self, root)
  local function run(node)
    if node.level == 0 then
      highlight_node(self, node, root)
      return
    end
    for _, child in pairs(node.children or {}) do
      run(child)
    end
  end
  run(root)
end

local function active(self, root)
  table.insert(self.state, root)
  highlight_nodes(self, root)
  vim.cmd.redraw()
  self:listen(root)
end

local function get_random_label(include, node)
  if node.remain == 0 then
    return
  end

  local random = math.random(#include)
  local label = include[random]
  if node.children[label] == nil then
    return label
  end

  return get_random_label(include, node)
end

local function compute(include, total)
  local label_count = #include
  local function compute_run(i)
    local min = label_count * math.pow(label_count, i - 1)
    local max = label_count * math.pow(label_count, i)

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

function M:clear_ns_id()
  for _, buf in ipairs(vim.tbl_keys(self.bufs)) do
    buf = tonumber(buf)
    vim.api.nvim_buf_clear_namespace(buf--[[@as integer]], self.ns_id, 0, -1)
  end
end

function M:listen(root)
  local char = vim.fn.getcharstr()
  local key = vim.fn.keytrans(char)
  self:clear_ns_id()

  if not root or root.children[char] == nil then
    finish(self)
    util.callback_option(self.config.unmatched, key)
    util.callback_option(self.config.on_key, {
      matched = nil,
      label = key,
    })
  else
    local node = root.children[char]
    if node.level == 0 then
      util.callback_option(node.matched and node.matched or self.config.matched, node.data)
      finish(self)
      util.callback_option(
        self.config.on_key,
        vim.tbl_deep_extend("force", {
          matched = true,
        }, node.data)
      )
    else
      active(self, node)
    end
  end
end

local function register_leaf(parent, label)
  if not label then
    return
  end
  local node = {
    level = 0,
    label = label,
    parent = parent,
    id = parent.id .. (#vim.tbl_keys(parent.children) + 1),
  }
  parent.children[label] = node
  parent.remain = parent.remain - 1
  return node
end

local function register_node(self, parent, label)
  if not label then
    return
  end
  local node = {
    level = parent.level - 1,
    label = label,
    parent = parent,
    remain = #self.config.label.include,
    children = {},
    id = parent.id .. (#vim.tbl_keys(parent.children) + 1),
  }
  parent.children[label] = node
  parent.remain = parent.remain - 1
  return node
end

--- @param label EyeTrack.LabelSpec
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
    local leaf = register_leaf(node, get_random_label(self.config.label.include, node))
    label.buf = label.buf or vim.api.nvim_get_current_buf()
    self.bufs[tostring(label.buf)] = true
    leaf.matched = label.matched
    leaf.highlight = label.highlight or {}
    leaf.hidden_next_key = label.hidden_next_key
    leaf.data = {
      line = label.line,
      col = label.col,
      label = leaf.label,
      data = label.data,
      buf = label.buf,
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
    node.current = register_node(self, node, get_random_label(self.config.label.include, node))
    self:_register(node.current, label)
  end
end

--- @param label EyeTrack.LabelSpec
function M:register(label)
  self:_register(self.root, label)
end

--- @param labels EyeTrack.LabelSpec[]
--- @param config? EyeTrack.Config
function M:init(labels, config)
  config = config or {}
  self.labels = labels
  self.config = {
    matched = config.matched,
    unmatched = config.unmatched,
    on_key = config.on_key,
    label = vim.tbl_deep_extend("force", default_config.label, config.label or {}),
  }
  local include = {}
  for _, label in ipairs(self.config.label.include) do
    if not vim.list_contains(self.config.label.exclude, label) then
      table.insert(include, label)
    end
  end
  self.config.label.include = include

  local level, remain1, remain2 = compute(self.config.label.include, #labels)
  self.root = {
    id = "0",
    level = level + 1,
    remain = remain2 + 1,
    children = {},
  }
  self.bufs = {}
  self.ns_id = vim.api.nvim_create_namespace("eye-track-namespace")
  self.state = {}
  self.finish_callbacks = {}
  self.begin_callbacks = {}
  self.root.current = register_node(self, self.root, "[[root]]")
  self.root.current.label = nil
  self.root.current.remain = remain1
  setmetatable(self.root.children, { __index = self.root.children["[[root]]"].children })
  require("eye-track.core.layer").access(config.layer, function(b, f)
    table.insert(self.begin_callbacks, b)
    table.insert(self.finish_callbacks, f)
  end)
end

function M:main()
  for _, label in ipairs(self.labels) do
    self:register(label)
  end
  self:active(self.root)
end

function M:active(root)
  begin(self)
  active(self, root)
end

--- @param labels table<EyeTrack.LabelSpec>
--- @param config? EyeTrack.Config
--- @return EyeTrack.Key
function M:new(labels, config)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  self.init(o, labels, config)
  return o
end

return M
