local class = require 'nelua.utils.class'
local errorer = require 'nelua.utils.errorer'
local tabler = require 'nelua.utils.tabler'
local metamagic = require 'nelua.utils.metamagic'
local iters = require 'nelua.utils.iterators'
local Attr = require 'nelua.attr'
local ASTNode = require 'nelua.astnode'
local config = require 'nelua.configer'.get()
local shaper = require 'nelua.utils.shaper'
local traits = require 'nelua.utils.traits'
local bn = require 'nelua.utils.bn'

local ASTBuilder = class()

function ASTBuilder:_init()
  self.nodes = { Node = ASTNode }
  self.shaper = { node = { Node = shaper.ast_node_of(ASTNode) } }
  self.shapes = { Node = shaper.shape {} }
  self.aster = {}
  self.aster.value = function(...) return self:create_value(...) end
  metamagic.setmetaindex(self.shaper, shaper)
end

-- Create an AST node from a Lua value.
function ASTBuilder:create_value(val, srcnode)
  local node
  local aster = self.aster
  if traits.is_astnode(val) then
    node = val
  elseif traits.is_type(val) then
    node = aster.Type{'auto', pattr={
      type = require'nelua.typedefs'.primtypes.type,
      value = val
    }}
  elseif traits.is_string(val) then
    node = aster.String{val}
  elseif traits.is_symbol(val) then
    node = aster.Id{val.name, pattr={
      forcesymbol = val
    }}
  elseif bn.isnumeric(val) then
    local num = bn.parse(val)
    local neg = false
    if bn.isneg(num) then
      num = bn.abs(num)
      neg = true
    end
    if bn.isintegral(num) then
      node = aster.Number{'dec', bn.todec(num)}
    else
      local snum = bn.todecsci(num)
      local int, frac, exp = bn.splitdecsci(snum)
      node = aster.Number{'dec', int, frac, exp}
    end
    if neg then
      node = aster.UnaryOp{'unm', node}
    end
  elseif traits.is_boolean(val) then
    node = aster.Boolean{val}
  --TODO: table, nil
  end
  if node and srcnode then
    node.src = srcnode.src
    node.pos = srcnode.pos
    node.endpos = srcnode.endpos
  end
  return node
end

-- Register a new AST Node type described by a shape.
function ASTBuilder:register(tag, shape)
  shape.attr = shaper.table:is_optional()
  shape.uid = shaper.number:is_optional()
  -- create a new class for the AST Node
  local klass = class(ASTNode)
  klass.tag = tag
  klass.nargs = #shape
  self.nodes[tag] = klass
  self.shaper.node[tag] = shaper.ast_node_of(klass) -- shape checker used in astdefs
  self.shapes[tag] = shaper.shape(shape) -- shape checker used with 'check_ast_shape'
  -- allow calling the aster for creating any AST node.
  self.aster[tag] = function(params)
    local nargs = math.max(klass.nargs, #params)
    local node = self:create(tag, table.unpack(params, 1, nargs))
    for k,v in iters.spairs(params) do -- set all string keys
      node[k] = v
    end
    if params.pattr then -- merge persistent attributes
      node.attr:merge(params.pattr)
    end
    return node
  end
  return klass
end

-- Create a new AST Node from a tag and arguments.
function ASTBuilder:create(tag, ...)
  local klass = self.nodes[tag]
  if not klass then
    errorer.errorf("AST with name '%s' is not registered", tag)
  end
  local node = klass(...)
  if config.check_ast_shape then
    local shape = self.shapes[tag]
    local ok, err = shape(node)
    errorer.assertf(ok, 'invalid shape while creating AST node "%s": %s', tag, err)
  end
  return node
end

local genuid = ASTNode.genuid

-- Create an AST Node from tag, src, pos, endpos and arguments.
-- Used internally by the parser.
function ASTBuilder:_create(tag, src, pos, ...)
  local n = select('#', ...)
  local endpos = select(n, ...)
  local node = {
    src = src,
    pos = pos,
    endpos = endpos,
    uid = genuid(),
    attr = setmetatable({}, Attr),
  }
  for i=1,n-1 do
    node[i] = select(i, ...)
  end
  return setmetatable(node, self.nodes[tag])
end

function ASTBuilder:clone()
  local clone = ASTBuilder()
  tabler.update(clone.nodes, self.nodes)
  tabler.update(clone.shapes, self.shapes)
  tabler.update(clone.shaper, self.shaper)
  return clone
end

return ASTBuilder
