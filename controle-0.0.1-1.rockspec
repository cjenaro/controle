package = "controle"
version = "0.0.1-1"
source = {
   url = "git://github.com/foguete/controle.git",
   tag = "v0.0.1"
}
description = {
   summary = "Rails-like CLI and code generators for Foguete framework",
   detailed = [[
      Controle provides the 'fog' command-line interface for the Foguete framework,
      offering Rails-inspired project scaffolding, code generation, database management,
      and development tools with seamless integration across all Foguete packages.
   ]],
   homepage = "https://github.com/foguete/controle",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1",
   "luafilesystem >= 1.6.0"
}
build = {
   type = "builtin",
   modules = {
      ["controle"] = "src/init.lua",
      ["controle.cli"] = "src/cli.lua",
      ["controle.commands.new"] = "src/commands/new.lua",
      ["controle.commands.server"] = "src/commands/server.lua",
      ["controle.commands.console"] = "src/commands/console.lua",
      ["controle.commands.generate"] = "src/commands/generate.lua",
      ["controle.commands.db"] = "src/commands/db.lua",
      ["controle.generators.base_generator"] = "src/generators/base_generator.lua",
      ["controle.generators.model_generator"] = "src/generators/model_generator.lua",
      ["controle.generators.controller_generator"] = "src/generators/controller_generator.lua",
      ["controle.generators.migration_generator"] = "src/generators/migration_generator.lua",
      ["controle.generators.scaffold_generator"] = "src/generators/scaffold_generator.lua",
      ["controle.utils.file_utils"] = "src/utils/file_utils.lua",
      ["controle.utils.string_utils"] = "src/utils/string_utils.lua",
      ["controle.utils.template_engine"] = "src/utils/template_engine.lua"
   },
   install = {
      bin = {
         fog = "bin/fog"
      }
   },
}