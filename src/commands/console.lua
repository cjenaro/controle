-- fog console command - Interactive Lua console
local function safe_require(module_name, fallback_name)
    local ok, result = pcall(require, module_name)
    if ok then
        return result
    else
        return require(fallback_name)
    end
end

local FileUtils = safe_require("controle.utils.file_utils", "utils.file_utils")

local ConsoleCommand = {}

function ConsoleCommand.show_help()
    print([[
Usage: fog console [options]

Start an interactive Lua console with your application loaded.

Options:
    --help    Show this help message

The console provides access to:
    - All your models
    - Database connection
    - Application configuration
]])
end

function ConsoleCommand.load_environment()
    -- Load application configuration
    local ok, config = pcall(require, "config.application")
    if not ok then
        print("Warning: Could not load application configuration")
    end
    
    -- Initialize database if Carga is available
    local carga_ok, carga = pcall(require, "carga")
    if carga_ok then
        local db_path = "db/development.db"
        if config and config.database and config.database.path then
            db_path = config.database.path
        end
        
        carga.Database.connect(db_path)
        print("Database connected: " .. db_path)
    end
    
    -- Load all models
    local models = {}
    if FileUtils.is_directory("app/models") then
        local model_files = FileUtils.find_files("app/models", "%.lua$")
        
        for _, file_path in ipairs(model_files) do
            local model_name = FileUtils.get_basename(file_path)
            local module_path = file_path:gsub("%.lua$", ""):gsub("/", ".")
            
            local model_ok, model = pcall(require, module_path)
            if model_ok then
                models[model_name] = model
                _G[model_name] = model -- Make available globally
                print("Loaded model: " .. model_name)
            end
        end
    end
    
    return models
end

function ConsoleCommand.start_repl()
    print("Foguete Console")
    print("Type 'exit' to quit, 'help' for available commands")
    print("")
    
    while true do
        io.write("foguete> ")
        io.flush()
        
        local input = io.read()
        if not input then
            break
        end
        
        input = input:match("^%s*(.-)%s*$") -- trim whitespace
        
        if input == "exit" or input == "quit" then
            print("Goodbye!")
            break
        elseif input == "help" then
            print("Available commands:")
            print("  help     - Show this help")
            print("  exit     - Exit console")
            print("  models   - List loaded models")
            print("")
            print("You can also execute any Lua code.")
        elseif input == "models" then
            print("Loaded models:")
            for name, _ in pairs(_G) do
                if type(_G[name]) == "table" and _G[name].table_name then
                    print("  " .. name .. " (table: " .. _G[name].table_name .. ")")
                end
            end
        elseif input ~= "" then
            -- Try to execute as Lua code
            local chunk, compile_err = load("return " .. input)
            if not chunk then
                chunk, compile_err = load(input)
            end
            
            if chunk then
                local success, result = pcall(chunk)
                if success then
                    if result ~= nil then
                        print(tostring(result))
                    end
                else
                    print("Runtime error: " .. tostring(result))
                end
            else
                print("Syntax error: " .. tostring(compile_err))
            end
        end
    end
end

function ConsoleCommand.run(parsed_args)
    if parsed_args.options.help then
        ConsoleCommand.show_help()
        return true
    end
    
    print("Loading Foguete application...")
    
    -- Load environment and models
    ConsoleCommand.load_environment()
    
    -- Start interactive console
    ConsoleCommand.start_repl()
    
    return true
end

return ConsoleCommand