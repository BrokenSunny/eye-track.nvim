--- @class EyeTrack.Label.Node
--- @field id string
--- @field level integer
--- @field remain integer
--- @field parent? EyeTrack.Label.Node
--- @field children table<string, EyeTrack.Label.Node|EyeTrack.Label.Leaf>
--- @field label? string

--- @class EyeTrack.Label.Leaf: EyeTrack.Label.Node
--- @field spec EyeTrack.LabelSpec

--- @class EyeTrack.Label
--- @field config EyeTrack.Label.Config
--- @field labels EyeTrack.LabelSpec[]
--- @field root EyeTrack.Label.Node
--- @field bufs table<string, boolean>
--- @field ns_id integer
local M = {}
local util = require("eye-track.core.util")

--- @type EyeTrack.Label.Config
local default_config = {
  sublabel = {
    relative_position = function(relative)
      return { row = relative.row, col = relative.col + 1 }
    end,
  },
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
}

--- @param leaf EyeTrack.Label.Leaf
--- @param root EyeTrack.Label.Node
--- @return EyeTrack.Label.Node[]
local function get_leaf_ancestor_list(leaf, root)
  --- @type EyeTrack.Label.Node[]
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
  local extmark_opts = {
    virt_text_pos = options.virt_text_pos or "overlay",
    virt_text = { { options.text, options.hl_group } },
    hl_mode = "combine",
  }
  if options.virt then
    extmark_opts.virt_text_win_col = col
    vim.api.nvim_buf_set_extmark(options.buf, ns_id, line, 0, extmark_opts)
  else
    vim.api.nvim_buf_set_extmark(options.buf, ns_id, line, col, extmark_opts)
  end
end

--- @param highlight EyeTrack.LabelSpec.Highlight
local function normalize_highlight(highlight)
  if type(highlight.hl_group) == "function" then
    highlight.hl_group = highlight.hl_group({})
  end
  if type(highlight.hl_group) ~= "table" then
    highlight.hl_group = { "EyeTrackKey", "EyeTrackNextKey" }
  end
  return highlight
end

--- @param self EyeTrack.Label
--- @param leaf EyeTrack.Label.Leaf
--- @param root EyeTrack.Label.Node
local function highlight_node(self, leaf, root)
  local ancestor_list = get_leaf_ancestor_list(leaf, root)
  local highlight = normalize_highlight(leaf.spec.highlight or {})
  local relative_postion = { row = 0, col = -1 }

  local function hl(i, node)
    for index, label in ipairs(leaf.spec.labels) do
      if index == 1 then
        relative_postion = self.config.sublabel.relative_position(relative_postion, {
          row = label.row,
          col = label.col,
        })
      end
      if node.level == 0 then
        util.callback_option(highlight.HighlightPre, self.ns_id)
      end

      if leaf.spec.hidden_next_key and i ~= 1 then
        return
      end

      local row = label.row + relative_postion.row
      local col = label.col + relative_postion.col
      set_extmark({
        buf = leaf.spec.buf,
        line = row,
        virt = leaf.spec.virt,
        virt_text_pos = leaf.spec.virt_text_pos,
        col = col,
        ns_id = self.ns_id,
        hl_group = highlight.hl_group[i] or highlight.hl_group[#highlight.hl_group],
        text = node.label,
      })
    end
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

--- @param leaf EyeTrack.Label.Leaf |nil
local function finish(self, leaf, ctx)
  if ctx.matched then
    local matched = leaf and leaf.spec.matched
    matched = matched or self.config.matched
    util.callback_option(matched, ctx)
  else
    util.callback_option(self.config.unmatched, ctx)
  end
  util.callback_option(self.config.finish, ctx)
end

--- @param leaf EyeTrack.Label.Leaf
local function create_context(leaf)
  return {
    label = leaf.label,
    labels = leaf.spec.labels,
    data = leaf.spec.data,
  }
end

--- @param self EyeTrack.Label
--- @param root EyeTrack.Label.Node
local function active(self, root)
  local function listen()
    local char = vim.fn.getcharstr()
    local key = vim.fn.keytrans(char)
    self:clear_ns_id()

    if not root or root.children[char] == nil then
      finish(self, nil, {
        label = key,
        matched = nil,
      })
      vim.cmd.redraw()
    else
      local node = root.children[char]
      if node.level == 0 then
        local leaf = node --[[@as EyeTrack.Label.Leaf]]
        local ctx = create_context(leaf)
        ctx.matched = true
        finish(self, leaf, ctx)
      else
        active(self, node)
      end
    end
  end
  highlight_nodes(self, root)
  vim.cmd.redraw()
  listen()
end

--- @return string|nil
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

--- @param parent EyeTrack.Label.Node
--- @param label string|nil
--- @return EyeTrack.Label.Leaf|nil
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

--- @param self EyeTrack.Label
--- @param parent EyeTrack.Label.Node
--- @param label string|nil
--- @return EyeTrack.Label.Node|nil
local function register_node(self, parent, label)
  if not label or label == "" then
    return
  end
  --- @type EyeTrack.Label.Node
  local node = {
    level = parent.level - 1,
    label = label,
    parent = parent,
    remain = #self.config.include,
    children = {},
    id = parent.id .. (#vim.tbl_keys(parent.children) + 1),
  }
  parent.children[label] = node
  parent.remain = parent.remain - 1
  return node
end

function M:clear_ns_id()
  for _, buf in ipairs(vim.tbl_keys(self.bufs)) do
    buf = tonumber(buf)
    vim.api.nvim_buf_clear_namespace(buf--[[@as integer]], self.ns_id, 0, -1)
  end
end

--- @param self EyeTrack.Label
--- @param node EyeTrack.Label.Node
--- @param label EyeTrack.LabelSpec
local function register(self, node, label)
  if not node then
    return
  end
  local function transfer()
    if node.parent then
      node.parent.current = nil
      register(self, node.parent, label)
    end
  end
  if node.level == 1 then
    if node.remain == 0 then
      transfer()
      return
    end
    local leaf = register_leaf(node, get_random_label(self.config.include, node))
    label.buf = label.buf or vim.api.nvim_get_current_buf()
    self.bufs[tostring(label.buf)] = true
    leaf.spec = {
      matched = label.matched,
      highlight = label.highlight or {},
      hidden_next_key = label.hidden_next_key,
      data = label.data,
      buf = label.buf,
      virt = label.virt,
      virt_text_pos = label.virt_text_pos,
      labels = label.labels,
    }
  else
    if node.current then
      register(self, node.current, label)
      return
    end
    if node.remain == 0 then
      transfer()
      return
    end
    node.current = register_node(self, node, get_random_label(self.config.include, node))
    register(self, node.current, label)
  end
end

--- @param label EyeTrack.LabelSpec
function M:register(label)
  register(self, self.root, label)
end

function M:active()
  util.callback_option(self.config.start)
  active(self, self.root)
end

function M:main()
  for _, label in ipairs(self.labels) do
    self:register(label)
  end
  self:active()
end

--- @param self EyeTrack.Label
--- @param labels EyeTrack.LabelSpec[]
--- @param config? EyeTrack.Label.Config
local function init(self, labels, config)
  config = config or {}
  self.labels = labels
  self.config = vim.tbl_deep_extend("force", default_config, config or {})
  local include = {}
  for _, label in ipairs(self.config.include) do
    if not vim.list_contains(self.config.exclude, label) then
      table.insert(include, label)
    end
  end
  self.config.include = include

  local level, remain1, remain2 = compute(self.config.include, #labels)
  --- @type EyeTrack.Label.Node
  self.root = {
    id = "0",
    level = level + 1,
    remain = remain2 + 1,
    children = {},
  }
  self.bufs = {}
  self.ns_id = vim.api.nvim_create_namespace("eye-track-namespace")
  self.root.current = register_node(self, self.root, "[[root]]")
  self.root.current.label = nil
  self.root.current.remain = remain1
  setmetatable(self.root.children, { __index = self.root.children["[[root]]"].children })
end

--- @param labels EyeTrack.LabelSpec[]
--- @param config? EyeTrack.Label.Config
--- @return EyeTrack.Label
function M:new(labels, config)
  --- @type EyeTrack.Label
  ---@diagnostic disable-next-line: missing-fields
  local o = {}
  setmetatable(o, self)
  self.__index = self
  init(o, labels, config)
  return o
end

return M
