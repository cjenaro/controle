-- Controle - Rails-like CLI for Foguete Framework
-- Main package entry point

--- @class Controle
--- @field VERSION string Package version
--- @field commands table<string, table> Available CLI commands
--- @field generators table<string, table> Available code generators
--- @field CLI table Command line interface module
--- @field BaseGenerator table Base generator class
--- @field FileUtils table File system utilities
--- @field StringUtils table String manipulation utilities
--- @field TemplateEngine table Template rendering engine
local controle = {
    VERSION = "0.0.1",
    commands = {},
    generators = {}
}

-- Helper function to require modules with fallback
local function safe_require(module_name, fallback_name)
    local ok, result = pcall(require, module_name)
    if ok then
        return result
    else
        return require(fallback_name)
    end
end

-- Load core modules
controle.CLI = safe_require("controle.cli", "cli")
controle.BaseGenerator = safe_require("controle.generators.base_generator", "generators.base_generator")

-- Load utilities
controle.FileUtils = safe_require("controle.utils.file_utils", "utils.file_utils")
controle.StringUtils = safe_require("controle.utils.string_utils", "utils.string_utils")
controle.TemplateEngine = safe_require("controle.utils.template_engine", "utils.template_engine")

-- Load commands
controle.commands.new = safe_require("controle.commands.new", "commands.new")
controle.commands.server = safe_require("controle.commands.server", "commands.server")
controle.commands.console = safe_require("controle.commands.console", "commands.console")
controle.commands.generate = safe_require("controle.commands.generate", "commands.generate")
controle.commands.db = safe_require("controle.commands.db", "commands.db")

-- Load generators
controle.generators.model = safe_require("controle.generators.model_generator", "generators.model_generator")
controle.generators.controller = safe_require("controle.generators.controller_generator", "generators.controller_generator")
controle.generators.migration = safe_require("controle.generators.migration_generator", "generators.migration_generator")
controle.generators.scaffold = safe_require("controle.generators.scaffold_generator", "generators.scaffold_generator")

--- Main CLI entry point
--- @param args table<number, string> Command line arguments
--- @return boolean success True if command executed successfully
function controle.run(args)
    return controle.CLI.run(args)
end

--- Show version information for Controle and other Foguete packages
--- @return nil
function controle.version()
    print("Controle CLI v" .. controle.VERSION)
    print("Part of the Foguete Framework")
    
    -- Try to show versions of other Foguete packages
    local packages = { "motor", "rota", "comando", "carga", "orbita" }
    
    for _, package in ipairs(packages) do
        local ok, pkg = pcall(require, package)
        if ok and pkg.VERSION then
            print(package .. " v" .. pkg.VERSION)
        end
    end
end

return controle