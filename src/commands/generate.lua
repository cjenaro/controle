-- fog generate command - Code generation
local GenerateCommand = {}

function GenerateCommand.show_help()
    print([[
Usage: fog generate <type> <name> [options]

Generate code scaffolds for your Foguete application.

Types:
    model <name> [field:type ...]       Generate Carga model with migration
    controller <name> [action ...]      Generate Comando controller
    migration <name>                    Generate database migration
    scaffold <name> [field:type ...]    Generate model + controller + views + migration

Field Types:
    string      Text field (default)
    text        Long text field
    integer     Numeric field
    boolean     True/false field
    datetime    Timestamp field
    references  Foreign key (e.g., user:references)

Options:
    --force     Overwrite existing files
    --help      Show this help message

Examples:
    fog generate model User name:string email:string age:integer
    fog generate controller Users index show create update destroy
    fog generate migration AddEmailToUsers email:string
    fog generate scaffold Post title:string content:text user:references
]])
end

function GenerateCommand.run(parsed_args)
    if parsed_args.options.help then
        GenerateCommand.show_help()
        return true
    end
    
    local generator_type = parsed_args.subcommand
    local name = parsed_args.args[1]
    
    if not generator_type then
        print("Error: Generator type is required")
        GenerateCommand.show_help()
        return false
    end
    
    if not name then
        print("Error: Name is required")
        GenerateCommand.show_help()
        return false
    end
    
    -- Parse additional arguments based on generator type
    local options = {
        force = parsed_args.options.force
    }
    
    if generator_type == "model" or generator_type == "scaffold" then
        -- Parse field specifications
        options.fields = {}
        for i = 2, #parsed_args.args do
            table.insert(options.fields, parsed_args.args[i])
        end
    elseif generator_type == "controller" then
        -- Parse action names
        options.actions = {}
        for i = 2, #parsed_args.args do
            table.insert(options.actions, parsed_args.args[i])
        end
        
        -- Default actions if none specified
        if #options.actions == 0 then
            options.actions = { "index", "show", "create", "update", "destroy" }
        end
    end
    
    -- Load and run the appropriate generator
    local generator_module_name = "controle.generators." .. generator_type .. "_generator"
    local ok, generator_class = pcall(require, generator_module_name)
    
    if not ok then
        print("Error: Unknown generator type '" .. generator_type .. "'")
        GenerateCommand.show_help()
        return false
    end
    
    -- Prepare arguments for generator
    local generator_args = {
        subcommand = name,
        args = {},
        options = parsed_args.options
    }
    
    -- Add remaining arguments
    for i = 2, #parsed_args.args do
        table.insert(generator_args.args, parsed_args.args[i])
    end
    
    -- Run generator
    return generator_class.run(generator_args)
end

return GenerateCommand