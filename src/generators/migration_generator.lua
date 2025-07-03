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
--- @return string field_name Extracted field name (for add/remove operations)
function MigrationGenerator:detect_migration_type(migration_name)
    -- Convert to underscore format first, then lowercase
    local underscored_name = StringUtils.underscore(migration_name)
    local lower_name = underscored_name:lower()
    
    -- Create table patterns
    if lower_name:match("^create_") then
        local table_name = lower_name:gsub("^create_", "")
        return "create_table", table_name, nil
    end
    
    -- Add column patterns
    if lower_name:match("^add_.*_to_") then
        local table_name = lower_name:match("_to_(.+)$")
        local field_part = lower_name:match("^add_(.+)_to_")
        return "add_column", table_name, field_part
    end
    
    -- Remove column patterns
    if lower_name:match("^remove_.*_from_") then
        local table_name = lower_name:match("_from_(.+)$")
        local field_part = lower_name:match("^remove_(.+)_from_")
        return "remove_column", table_name, field_part
    end
    
    -- Drop table patterns
    if lower_name:match("^drop_") then
        local table_name = lower_name:gsub("^drop_", "")
        return "drop_table", table_name, nil
    end
    
    -- Change column patterns (change_field_from_old_to_new or rename_field_to_new)
    if lower_name:match("^change_.*_from_.*_to_") then
        local table_name = lower_name:match("_in_(.+)$") or lower_name:match("_from_.*_to_(.+)$")
        local field_part = lower_name:match("^change_(.+)_from_")
        return "change_column", table_name, field_part
    end
    
    if lower_name:match("^rename_.*_to_.*_in_") then
        local table_name = lower_name:match("_in_(.+)$")
        local field_part = lower_name:match("^rename_(.+)_to_")
        return "rename_column", table_name, field_part
    end
    
    -- Default to generic migration
    return "generic", nil, nil
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
        local statement = string.format('        db:execute("ALTER TABLE %s ADD COLUMN %s %s")', 
            table_name, field.name, field.sql_type)
        table.insert(statements, statement)
    end
    
    return table.concat(statements, "\n")
end

--- Generate commented add column statements
--- @param table_name string Table name
--- @param fields table<number, table> Field definitions
--- @return string Commented add column statements
function MigrationGenerator:generate_add_columns_commented(table_name, fields)
    local statements = {}
    
    for _, field in ipairs(fields) do
        local statement = string.format('        -- db:execute("ALTER TABLE %s ADD COLUMN %s %s")', 
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
        -- Use the new drop_column method which handles SQLite limitations
        local statement = string.format('        db:drop_column("%s", "%s")', 
            table_name, field.name)
        table.insert(statements, statement)
    end
    
    return table.concat(statements, "\n")
end

--- Generate commented remove column statements
--- @param table_name string Table name
--- @param fields table<number, table> Field definitions
--- @return string Commented remove column statements
function MigrationGenerator:generate_remove_columns_commented(table_name, fields)
    local statements = {}
    
    for _, field in ipairs(fields) do
        local statement = string.format('        -- db:drop_column("%s", "%s")', 
            table_name, field.name)
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
        table.insert(field_defs, string.format("                %s %s", field.name, field.sql_type))
    end
    
    return table.concat(field_defs, ",\n")
end

--- Generate model-based add column statements
--- @param table_name string Table name
--- @param fields table<number, table> Field definitions
--- @param field_name_from_migration string? Field name extracted from migration name
--- @param field_type_from_args string? Field type from command line args
--- @return string Model-based add column statements
function MigrationGenerator:generate_model_add_columns(table_name, fields, field_name_from_migration, field_type_from_args)
    local model_name = StringUtils.camelize(StringUtils.singularize(table_name))
    local statements = {
        string.format("        local %s = db:model(\"%s\")", model_name, model_name)
    }
    
    -- If we have fields from command line, use those
    if #fields > 0 then
        for _, field in ipairs(fields) do
            local statement = string.format('        db:add_field_to_model(%s, "%s", "%s")', 
                model_name, field.name, field.sql_type)
            table.insert(statements, statement)
        end
    -- If we have a field name from migration name, use that
    elseif field_name_from_migration then
        local field_type = field_type_from_args or "TEXT" -- use provided type or default
        local statement = string.format('        db:add_field_to_model(%s, "%s", "%s")', 
            model_name, field_name_from_migration, field_type)
        table.insert(statements, statement)
    else
        return "        -- local Model = db:model(\"ModelName\")\n        -- db:add_field_to_model(Model, \"field_name\", \"TEXT\")"
    end
    
    return table.concat(statements, "\n")
end

--- Generate model-based remove column statements
--- @param table_name string Table name
--- @param fields table<number, table> Field definitions
--- @param field_name_from_migration string? Field name extracted from migration name
--- @param field_type_from_args string? Field type from command line args (for rollback)
--- @return string Model-based remove column statements
function MigrationGenerator:generate_model_remove_columns(table_name, fields, field_name_from_migration, field_type_from_args)
    local model_name = StringUtils.camelize(StringUtils.singularize(table_name))
    local statements = {
        string.format("        local %s = db:model(\"%s\")", model_name, model_name)
    }
    
    -- If we have fields from command line, use those
    if #fields > 0 then
        for _, field in ipairs(fields) do
            local statement = string.format('        db:remove_field_from_model(%s, "%s")', 
                model_name, field.name)
            table.insert(statements, statement)
        end
    -- If we have a field name from migration name, use that
    elseif field_name_from_migration then
        local statement = string.format('        db:remove_field_from_model(%s, "%s")', 
            model_name, field_name_from_migration)
        table.insert(statements, statement)
    else
        return "        -- local Model = db:model(\"ModelName\")\n        -- db:remove_field_from_model(Model, \"field_name\")"
    end
    
    return table.concat(statements, "\n")
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
    
    -- Detect migration type and extract table name and field name
    local migration_type, table_name, field_name_from_migration = generator:detect_migration_type(migration_name)
    
    -- Parse field definitions if provided
    local fields = {}
    if migration_type == "add_column" or migration_type == "remove_column" or migration_type == "create_table" then
        fields = generator:parse_add_column_fields(parsed_args.args)
    end
    
    -- For remove/add operations, if we have a field name from migration name but no field args,
    -- try to find the field type from the args
    local field_type_from_args = nil
    if (migration_type == "add_column" or migration_type == "remove_column") and field_name_from_migration and #fields == 0 and #parsed_args.args > 0 then
        -- The args might be just "description:text" - parse it
        for _, arg in ipairs(parsed_args.args) do
            local name, ftype = arg:match("^([^:]+):(.+)$")
            if name == field_name_from_migration then
                field_type_from_args = generator:lua_to_sql_type(ftype)
                break
            end
        end
    end
    
    -- Generate timestamp and file name
    local timestamp = os.date("%Y%m%d%H%M%S")
    local file_name = StringUtils.underscore(migration_name)
    local migration_path = "db/migrate/" .. timestamp .. "_" .. file_name .. ".lua"
    
    -- Generate template variables based on migration type
    local template_vars = {
        migration_name = StringUtils.camelize(migration_name),
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        table_name = table_name or "table_name",
        model_name = table_name and StringUtils.camelize(StringUtils.singularize(table_name)) or "ModelName"
    }
    
    local template_file
    
    if migration_type == "create_table" then
        template_file = "migration/create_table.lua"
        template_vars.table_fields = generator:generate_table_fields(fields)
        template_vars.indexes = "        -- Add indexes here if needed"
        
    elseif migration_type == "add_column" then
        template_file = "migration/add_column.lua"
        template_vars.add_columns = generator:generate_add_columns(table_name, fields)
        template_vars.remove_columns = generator:generate_remove_columns(table_name, fields)
        template_vars.add_columns_commented = generator:generate_add_columns_commented(table_name, fields)
        template_vars.remove_columns_commented = generator:generate_remove_columns_commented(table_name, fields)
        template_vars.model_add_columns = generator:generate_model_add_columns(table_name, fields, field_name_from_migration, field_type_from_args)
        template_vars.model_remove_columns = generator:generate_model_remove_columns(table_name, fields, field_name_from_migration, field_type_from_args)
        
    elseif migration_type == "remove_column" then
        template_file = "migration/add_column.lua"
        template_vars.add_columns = generator:generate_remove_columns(table_name, fields)
        template_vars.remove_columns = generator:generate_add_columns(table_name, fields)
        template_vars.add_columns_commented = generator:generate_remove_columns_commented(table_name, fields)
        template_vars.remove_columns_commented = generator:generate_add_columns_commented(table_name, fields)
        -- For remove_column, the up action is remove and down action is add
        template_vars.model_add_columns = generator:generate_model_remove_columns(table_name, fields, field_name_from_migration, field_type_from_args)
        template_vars.model_remove_columns = generator:generate_model_add_columns(table_name, fields, field_name_from_migration, field_type_from_args)
        
    else
        -- Generic migration
        template_file = "migration/add_column.lua"
        template_vars.add_columns = "        -- Add your migration logic here"
        template_vars.remove_columns = "        -- Add your rollback logic here"
        template_vars.add_columns_commented = "        -- Add your migration logic here"
        template_vars.remove_columns_commented = "        -- Add your rollback logic here"
        template_vars.model_add_columns = "        -- local Model = db:model(\"ModelName\")\n        -- db:add_field_to_model(Model, \"field_name\", \"TEXT\")"
        template_vars.model_remove_columns = "        -- local Model = db:model(\"ModelName\")\n        -- db:remove_field_from_model(Model, \"field_name\")"
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