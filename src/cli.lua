-- CLI command parser and dispatcher
local lfs = require("lfs")

--- @class CLI
--- @field parse_args function Parse command line arguments
--- @field show_help function Show help information
--- @field show_version function Show version information
--- @field in_foguete_app function Check if in Foguete app directory
--- @field run function Main CLI dispatcher
local CLI = {}

--- Parse command line arguments into structured format
--- @param args table<number, string> Raw command line arguments
--- @return table parsed Parsed arguments with command, subcommand, args, and options
function CLI.parse_args(args)
    local command = args[1]
    local subcommand = args[2]
    local options = {}
    local positional = {}
    
    -- Parse flags and options
    local i = 1
    while i <= #args do
        local arg = args[i]
        
        if arg:match("^%-%-") then
            -- Long option (--help, --version)
            local key = arg:gsub("^%-%-", "")
            if args[i + 1] and not args[i + 1]:match("^%-") then
                options[key] = args[i + 1]
                i = i + 1
            else
                options[key] = true
            end
        elseif arg:match("^%-") then
            -- Short option (-h, -v)
            local key = arg:gsub("^%-", "")
            if args[i + 1] and not args[i + 1]:match("^%-") then
                options[key] = args[i + 1]
                i = i + 1
            else
                options[key] = true
            end
        else
            -- Positional argument
            table.insert(positional, arg)
        end
        
        i = i + 1
    end
    
    return {
        command = positional[1],
        subcommand = positional[2],
        args = { table.unpack(positional, 3) },
        options = options
    }
end

--- Show help information for the CLI
--- @return nil
function CLI.show_help()
    print([[
Fog - Foguete Framework CLI

USAGE:
    fog <COMMAND> [OPTIONS]

COMMANDS:
    new <name>              Create a new Foguete application
    server                  Start the development server
    console                 Start an interactive console
    generate <type> <name>  Generate code (model, controller, migration, scaffold)
    db <action>            Database commands (create, migrate, rollback, seed, reset)
    test [type]            Run tests (all, models, controllers)
    version                Show version information

EXAMPLES:
    fog new my_app                           # Create new application
    fog generate model User name:string     # Generate User model
    fog generate controller Users           # Generate Users controller
    fog generate scaffold Post title:string # Generate complete CRUD
    fog db:migrate                          # Run database migrations
    fog server                              # Start development server

For more information on a specific command, use:
    fog <command> --help
]])
end

--- Show version information
--- @return nil
function CLI.show_version()
    local controle = require("controle")
    controle.version()
end

--- Check if we're in a Foguete application directory
--- @return boolean inApp True if in a Foguete app directory
function CLI.in_foguete_app()
    return lfs.attributes("server.lua") or lfs.attributes("config/application.lua")
end

--- Main CLI dispatcher - routes commands to appropriate handlers
--- @param args table<number, string> Command line arguments
--- @return boolean success True if command executed successfully
function CLI.run(args)
    if #args == 0 then
        CLI.show_help()
        return true
    end
    
    local parsed = CLI.parse_args(args)
    
    -- Handle global options
    if parsed.options.help or parsed.options.h then
        CLI.show_help()
        return true
    end
    
    if parsed.options.version or parsed.options.v or parsed.command == "version" then
        CLI.show_version()
        return true
    end
    
    -- Handle database commands with colon syntax (db:migrate)
    if parsed.command and parsed.command:match("^db:") then
        local db_action = parsed.command:gsub("^db:", "")
        parsed.command = "db"
        parsed.subcommand = db_action
    end
    
    -- Load and execute command
    local command_name = parsed.command
    if not command_name then
        CLI.show_help()
        return false
    end
    
    -- Check if command requires being in a Foguete app (except 'new' and 'version')
    if command_name ~= "new" and command_name ~= "version" and not CLI.in_foguete_app() then
        print("Error: You must be in a Foguete application directory to run this command.")
        print("Use 'fog new <app_name>' to create a new application.")
        return false
    end
    
    -- Load command module
    local command_module_name = "controle.commands." .. command_name
    local ok, command_module = pcall(require, command_module_name)
    
    if not ok then
        print("Error: Unknown command '" .. command_name .. "'")
        print("Run 'fog --help' for available commands.")
        return false
    end
    
    -- Execute command
    local success, result = pcall(command_module.run, parsed)
    
    if not success then
        print("Error executing command: " .. tostring(result))
        return false
    end
    
    return result
end

return CLI