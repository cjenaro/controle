-- Migration generator for database schema changes
local function safe_require(module_name, fallback_name)
    local ok, result = pcall(require, module_name)
    if ok then
        return result
    else
        return require(fallback_name)
    end
end

local BaseGenerator = safe_require("controle.generators.base_generator", "generators.base_generator")
local StringUtils = safe_require("controle.utils.string_utils", "utils.string_utils")

--- @class MigrationGenerator : BaseGenerator
local MigrationGenerator = BaseGenerator:extend("MigrationGenerator")

--- Detect migration type from name
--- @param migration_name string Migration name
--- @return string migration_type Type of migration (create_table, add_column, etc.)
--- @return string table_name Extracted table name
function MigrationGenerator:detect_migration_type(migration_name)
    local lower_name = migration_name:lower()
    
    -- Create table patterns
    if lower_name:match("^create_") then
        local table_name = lower_name:gsub("^create_", "")
        return "create_table", table_name
    end
    
    -- Add column patterns
    if lower_name:match("^add_.*_to_") then
        local table_name = lower_name:match("_to_(.+)$")
        return "add_column", table_name
    end
    
    -- Remove column patterns
    if lower_name:match("^remove_.*_from_") then
        local table_name = lower_name:match("_from_(.+)$")
        return "remove_column", table_name
    end
    
    -- Drop table patterns
    if lower_name:match("^drop_") then
        local table_name = lower_name:gsub("^drop_", "")
        return "drop_table", table_name
    end
    
    -- Default to generic migration
    return "generic", nil
end

--- Parse field definitions for add_column migrations
--- @param fields table<number, string> Field definitions
--- @return table<number, table> Parsed field definitions
function MigrationGenerator:parse_add_column_fields(fields)
    local parsed_fields = {}
    
    for _, field_def in ipairs(fields) do
        local name, field_type = field_def:match("^([^:]+):(.+)$")
        if name and field_type then
            local field = {
                name = name,
                type = field_type,
                sql_type = self:lua_to_sql_type(field_type)
            }
            table.insert(parsed_fields, field)
        end
    end
    
    return parsed_fields
end

--- Convert Lua type to SQL type
--- @param lua_type string Lua type
--- @return string SQL type
function MigrationGenerator:lua_to_sql_type(lua_type)
    local type_map = {
        string = "TEXT",
        text = "TEXT",
        integer = "INTEGER",
        number = "REAL",
        float = "REAL",
        boolean = "INTEGER",
        datetime = "DATETIME",
        date = "DATE",
        time = "TIME"
    }
    
    return type_map[lua_type] or "TEXT"
end

--- Generate add column statements
--- @param table_name string Table name
--- @param fields table<number, table> Field definitions
--- @return string Add column statements
function MigrationGenerator:generate_add_columns(table_name, fields)
    local statements = {}
    
    for _, field in ipairs(fields) do
        local statement = string.format('    db.execute("ALTER TABLE %s ADD COLUMN %s %s")', 
            table_name, field.name, field.sql_type)
        table.insert(statements, statement)
    end
    
    return table.concat(statements, "\n")
end

--- Generate remove column statements
--- @param table_name string Table name
--- @param fields table<number, table> Field definitions
--- @return string Remove column statements
function MigrationGenerator:generate_remove_columns(table_name, fields)
    local statements = {}
    
    for _, field in ipairs(fields) do
        -- SQLite doesn't support DROP COLUMN directly, so we need to recreate the table
        local statement = string.format('    -- Note: SQLite does not support DROP COLUMN\n    -- You may need to recreate the table without the %s column', field.name)
        table.insert(statements, statement)
    end
    
    return table.concat(statements, "\n")
end

--- Generate table fields for create table migration
--- @param fields table<number, table> Field definitions
--- @return string Table field definitions
function MigrationGenerator:generate_table_fields(fields)
    local field_defs = {}
    
    for _, field in ipairs(fields) do
        table.insert(field_defs, string.format("            %s %s", field.name, field.sql_type))
    end
    
    return table.concat(field_defs, ",\n")
end

--- Run the migration generator
--- @param parsed_args table Parsed command line arguments
--- @return boolean success True if generation succeeded
function MigrationGenerator.run(parsed_args)
    local generator = MigrationGenerator:new("migration", parsed_args.options)
    
    -- Get migration name
    local migration_name = parsed_args.subcommand
    if not migration_name then
        print("Error: Migration name is required")
        print("Usage: fog generate migration <MigrationName> [field:type ...]")
        print("Examples:")
        print("  fog generate migration CreateUsers name:string email:string")
        print("  fog generate migration AddEmailToUsers email:string")
        print("  fog generate migration RemoveAgeFromUsers age:integer")
        return false
    end
    
    -- Detect migration type and extract table name
    local migration_type, table_name = generator:detect_migration_type(migration_name)
    
    -- Parse field definitions if provided
    local fields = {}
    if migration_type == "add_column" or migration_type == "remove_column" or migration_type == "create_table" then
        fields = generator:parse_add_column_fields(parsed_args.args)
    end
    
    -- Generate timestamp and file name
    local timestamp = os.date("%Y%m%d%H%M%S")
    local file_name = StringUtils.underscore(migration_name)
    local migration_path = "db/migrate/" .. timestamp .. "_" .. file_name .. ".lua"
    
    -- Generate template variables based on migration type
    local template_vars = {
        migration_name = StringUtils.camelize(migration_name),
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        table_name = table_name or "table_name"
    }
    
    local template_file
    
    if migration_type == "create_table" then
        template_file = "migration/create_table.lua"
        template_vars.table_fields = generator:generate_table_fields(fields)
        template_vars.indexes = "    -- Add indexes here if needed"
        
    elseif migration_type == "add_column" then
        template_file = "migration/add_column.lua"
        template_vars.add_columns = generator:generate_add_columns(table_name, fields)
        template_vars.remove_columns = generator:generate_remove_columns(table_name, fields)
        
    elseif migration_type == "remove_column" then
        template_file = "migration/add_column.lua"
        template_vars.add_columns = generator:generate_remove_columns(table_name, fields)
        template_vars.remove_columns = generator:generate_add_columns(table_name, fields)
        
    else
        -- Generic migration
        template_file = "migration/add_column.lua"
        template_vars.add_columns = "    -- Add your migration logic here"
        template_vars.remove_columns = "    -- Add your rollback logic here"
    end
    
    -- Generate migration file
    generator:generate_from_template(template_file, migration_path, template_vars)
    
    generator:show_summary()
    
    print("\nNext steps:")
    print("  1. Review the generated migration in " .. migration_path)
    print("  2. Run the migration: fog db:migrate")
    print("  3. To rollback: fog db:rollback")
    
    return true
end

return MigrationGenerator