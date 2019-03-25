require 'busted.runner'()

local assert = require 'spec.assert'
local euluna_std_default = require 'euluna.parsers.euluna_std_default'
local analyzer = require 'euluna.analyzers.types.analyzer'
local c_generator = require 'euluna.generators.c.generator'
local euluna_parser = euluna_std_default.parser
local euluna_aster = euluna_std_default.aster
local except = require 'euluna.utils.except'
local AST = function(...) return euluna_aster:AST(...) end
local TAST = function(...) return euluna_aster:TAST(...) end

local function assert_gencode_equals(code, expected_code)
  local ast = assert.parse_ast(euluna_parser, code)
  ast = assert(analyzer.analyze(ast))
  local expected_ast = assert.parse_ast(euluna_parser, expected_code)
  expected_ast = assert(analyzer.analyze(expected_ast))
  local generated_code = assert(c_generator.generate(ast))
  local expected_generated_code = assert(c_generator.generate(expected_ast))
  assert.same(expected_generated_code, generated_code)
end

local function assert_analyze_ast(code, expected_ast)
  local ast = assert.parse_ast(euluna_parser, code)
  analyzer.analyze(ast)
  assert.same(tostring(expected_ast), tostring(ast))
end

local function assert_analyze_error(code, expected_error)
  local ast = assert.parse_ast(euluna_parser, code)
  local ok, e = except.try(function()
    analyzer.analyze(ast)
  end)
  assert(not ok, "analysis should fail")
  assert.contains(expected_error, e:get_message())
end

describe("Euluna should check types for", function()

it("local variable", function()
  assert_analyze_ast("local a: int",
    AST('Block', {
      AST('VarDecl', 'local', 'var', {
        TAST('int', 'TypedId', 'a', TAST('type', 'Type', 'int'))})
  }))

  assert_gencode_equals("local a = 1", "local a: int = 1")

  assert_analyze_ast("local a: int = 1",
    AST('Block', {
      AST('VarDecl', 'local', 'var',
        { TAST('int', 'TypedId', 'a', TAST('type', 'Type', 'int')) },
        { TAST('int', 'Number', 'int', '1') }),
  }))

  assert_analyze_ast("local a = 1 f(a)",
    AST('Block', {
      AST('VarDecl', 'local', 'var',
        { TAST('int', 'TypedId', 'a') },
        { TAST('int', 'Number', 'int', '1') }),
      AST('Call', {},
        { TAST('int', 'Id', "a") },
        AST('Id', "f"),
        true
      )
  }))

  assert_analyze_error("local a: int = 'string'", "is not conversible with")
  assert_analyze_error("local a: uint8 = 1.0", "is not conversible with")
end)

it("loop variables", function()
  assert_gencode_equals("for i=1,10 do end", "for i:int=1,10 do end")
  assert_analyze_error("for i:uint8=1.0,2 do end", "is not conversible with")
  assert_analyze_error("for i:uint8=1_u8,2 do end", "is not conversible with")
end)

it("unary operators", function()
  assert_gencode_equals("local a = not b", "local a: boolean = not b")
  assert_gencode_equals("local a = -1", "local a: int = -1")
  assert_analyze_error("local a = -1_u", "is not defined for type")
end)

it("binary operators", function()
  assert_gencode_equals("local a = 1 + 2", "local a: int = 1 + 2")
  assert_gencode_equals("local a = 1 + 2.0", "local a: number = 1 + 2.0")
  assert_gencode_equals("local a = 1_i8 + 2_u8", "local a: int16 = 1_i8 + 2_u8")
  assert_analyze_error("local a = 1 + 's'", "is not defined for type")
  assert_analyze_error("local a = -1_u", "is not defined for type")
end)

it("operation with parenthesis", function()
  assert_gencode_equals("local a = -(1)", "local a: int = -(1)")
end)

end)