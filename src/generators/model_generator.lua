-- Model generator for Carga ORM models
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

--- @class ModelGenerator : BaseGenerator
local ModelGenerator = BaseGenerator:extend("ModelGenerator")

--- Parse field definitions from command line arguments
--- @param fields table<number, string> Field definitions like "name:string", "age:integer"
--- @return table<number, table> Parsed field definitions
function ModelGenerator:parse_fields(fields)
    local parsed_fields = {}
    
    for _, field_def in ipairs(fields) do
        local name, field_type = field_def:match("^([^:]+):(.+)$")
        if name and field_type then
            local field = {
                name = name,
                type = field_type,
                sql_type = self:lua_to_sql_type(field_type),
                validation = self:get_default_validation(field_type)
            }
            table.insert(parsed_fields, field)
        end
    end
    
    return parsed_fields
end

--- Convert Lua type to SQL type
--- @param lua_type string Lua type (string, number, boolean, etc.)
--- @return string SQL type
function ModelGenerator:lua_to_sql_type(lua_type)
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

--- Get default validation for field type
--- @param field_type string Field type
--- @return string|nil Validation rule
function ModelGenerator:get_default_validation(field_type)
    local validations = {
        string = "required",
        text = "required",
        integer = "required, numeric",
        number = "required, numeric",
        boolean = "boolean"
    }
    
    return validations[field_type]
end

--- Generate field declarations for model class
--- @param fields table<number, table> Parsed field definitions
--- @return string Field declarations
function ModelGenerator:generate_field_declarations(fields)
    local declarations = {}
    
    for _, field in ipairs(fields) do
        table.insert(declarations, string.format("--- @field %s %s", field.name, field.type))
    end
    
    return table.concat(declarations, "\n")
end

--- Generate schema fields for model
--- @param fields table<number, table> Parsed field definitions
--- @return string Schema field definitions
function ModelGenerator:generate_schema_fields(fields)
    local schema_fields = {}
    
    for _, field in ipairs(fields) do
        local field_def = string.format('    %s = { type = "%s" }', field.name, field.sql_type:lower())
        table.insert(schema_fields, field_def)
    end
    
    return table.concat(schema_fields, ",\n")
end

--- Generate validations for model
--- @param fields table<number, table> Parsed field definitions
--- @param class_name string Class name for the model
--- @return string Validation definitions
function ModelGenerator:generate_validations(fields, class_name)
    local validations = {}
    
    for _, field in ipairs(fields) do
        if field.validation then
            local validation = string.format('    %s = "%s"', field.name, field.validation)
            table.insert(validations, validation)
        end
    end
    
    if #validations > 0 then
        return string.format("-- Validations\n%s.validations = {\n%s\n}", 
            class_name, table.concat(validations, ",\n"))
    else
        return "-- No validations defined"
    end
end

--- Generate test attributes for specs
--- @param fields table<number, table> Parsed field definitions
--- @return string Test attributes
function ModelGenerator:generate_test_attributes(fields)
    local attributes = {}
    
    for _, field in ipairs(fields) do
        local value = self:get_test_value(field.type)
        table.insert(attributes, string.format('                %s = %s', field.name, value))
    end
    
    return table.concat(attributes, ",\n")
end

--- Get test value for field type
--- @param field_type string Field type
--- @return string Test value
function ModelGenerator:get_test_value(field_type)
    local test_values = {
        string = '"test_value"',
        text = '"test text content"',
        integer = '42',
        number = '3.14',
        boolean = 'true',
        datetime = '"2023-01-01 12:00:00"',
        date = '"2023-01-01"',
        time = '"12:00:00"'
    }
    
    return test_values[field_type] or '"test_value"'
end

--- Run the model generator
--- @param parsed_args table Parsed command line arguments
--- @return boolean success True if generation succeeded
function ModelGenerator.run(parsed_args)
    local generator = ModelGenerator:new("model", parsed_args.options)
    
    -- Get model name
    local model_name = parsed_args.subcommand
    if not model_name then
        print("Error: Model name is required")
        print("Usage: fog generate model <ModelName> [field:type ...]")
        print("Example: fog generate model User name:string email:string age:integer")
        return false
    end
    
    -- Parse field definitions
    local fields = generator:parse_fields(parsed_args.args)
    
    -- Generate template variables
    local class_name = StringUtils.camelize(model_name)
    local file_name = StringUtils.underscore(model_name)
    local table_name = StringUtils.pluralize(StringUtils.underscore(model_name))
    local instance_name = StringUtils.underscore(model_name)
    
    local template_vars = {
        class_name = class_name,
        file_name = file_name,
        table_name = table_name,
        instance_name = instance_name,
        field_declarations = generator:generate_field_declarations(fields),
        schema_fields = generator:generate_schema_fields(fields),
        validations = generator:generate_validations(fields, class_name),
        associations = "-- Define associations here",
        custom_methods = "-- Add custom methods here",
        valid_attributes = generator:generate_test_attributes(fields),
        validation_tests = "        -- Add validation tests here",
        association_tests = "        -- Add association tests here",
        custom_method_tests = "        -- Add custom method tests here"
    }
    
    -- Generate model file
    local model_path = "app/models/" .. file_name .. ".lua"
    generator:generate_from_template("model/model.lua", model_path, template_vars)
    
    -- Generate spec file
    local spec_path = "spec/models/" .. file_name .. "_spec.lua"
    generator:generate_from_template("model/spec.lua", spec_path, template_vars)
    
    -- Generate migration
    local migration_name = "create_" .. table_name
    local timestamp = os.date("%Y%m%d%H%M%S")
    local migration_path = "db/migrate/" .. timestamp .. "_" .. migration_name .. ".lua"
    
    -- Generate migration fields
    local migration_fields = {}
    for _, field in ipairs(fields) do
        table.insert(migration_fields, string.format("            %s %s", field.name, field.sql_type))
    end
    
    local migration_vars = {
        migration_name = StringUtils.camelize(migration_name),
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        table_name = table_name,
        table_fields = table.concat(migration_fields, ",\n"),
        indexes = "    -- Add indexes here if needed"
    }
    
    generator:generate_from_template("migration/create_table.lua", migration_path, migration_vars)
    
    generator:show_summary()
    
    print("\nNext steps:")
    print("  1. Review the generated model in " .. model_path)
    print("  2. Run the migration: fog db:migrate")
    print("  3. Run the tests: fog test models")
    
    return true
end

return ModelGenerator