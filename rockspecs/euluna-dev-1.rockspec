package = 'euluna'
version = 'dev-1'

source = {
  url = "git://github.com/edubart/euluna-lang",
  branch = "master"
}

description = {
  summary = 'The Euluna Programming Language.',
  detailed = [[
Euluna is a minimalistic, performant, safe, optionally typed, meta programmable,
systems programming language with syntax close to Lua language that works
either dynamically or staticaly by compiling to Lua or C.
]],
  maintainer = "Eduardo Bart <edub4rt@gmail.com>",
  homepage = 'https://github.com/edubart/euluna-lang',
  license = 'MIT <http://opensource.org/licenses/MIT>'
}

dependencies = {
  'penlight >= 1.5.4',
  'lpeglabel >= 1.5.0',
  'tableshape >= 2.0.0',
  'inspect >= 3.1.1',
  'lua-term >= 0.7',
  'argparse >= 0.6.0',
  'sha1 >= 0.6.0',

  -- dev dependencies only
  'busted >= 2.0rc13',
  'luacheck >= 0.23.0',
  'luacov >= 0.13.0',
  'cluacov >= 0.1.1',
}

build = {
  type = 'builtin',
  modules = {
    ['euluna/generator.lua'] = 'euluna/generator.lua',
    ['euluna/grammar.lua'] = 'euluna/grammar.lua',
    ['euluna/parser.lua'] = 'euluna/parser.lua',
    ['euluna/runner.lua'] = 'euluna/runner.lua',
    ['euluna/scope.lua'] = 'euluna/scope.lua',
    ['euluna/shaper.lua'] = 'euluna/shaper.lua',
    ['euluna/traverser.lua'] = 'euluna/traverser.lua',
    ['euluna/compilers/lua_compiler.lua'] = 'euluna/compilers/lua_compiler.lua',
    ['euluna/compilers/c_compiler.lua'] = 'euluna/compilers/c_compiler.lua',
    ['euluna/generators/c_generator.lua'] = 'euluna/generators/c_generator.lua',
    ['euluna/generators/lua_generator.lua'] = 'euluna/generators/lua_generator.lua',
    ['euluna/parsers/euluna_parser.lua'] = 'euluna/parsers/euluna_parser.lua',
  },
  install = {
    bin = {
      ['euluna'] = 'euluna.lua'
    }
  }
}
