-- Base generator class for all code generators
local function safe_require(module_name, fallback_name)
    local ok, result = pcall(require, module_name)
    if ok then
        return result
    else
        return require(fallback_name)
    end
end

local FileUtils = safe_require("controle.utils.file_utils", "utils.file_utils")
local StringUtils = safe_require("controle.utils.string_utils", "utils.string_utils")
local TemplateEngine = safe_require("controle.utils.template_engine", "utils.template_engine")

--- @class BaseGenerator
--- @field name string Generator name
--- @field options table<string, any> Generator options
--- @field files_created table<number, string> List of created files
--- @field directories_created table<number, string> List of created directories
--- @field class_name string? Generator class name
local BaseGenerator = {}
BaseGenerator.__index = BaseGenerator

--- Create new generator instance
--- @param name string Generator name
--- @param options table<string, any>? Generator options
--- @return BaseGenerator generator New generator instance
function BaseGenerator:new(name, options)
    local generator = {
        name = name,
        options = options or {},
        files_created = {},
        directories_created = {}
    }
    
    setmetatable(generator, self)
    return generator
end

--- Extend generator class for inheritance
--- @param class_name string Name of the new generator class
--- @return BaseGenerator new_class Extended generator class
function BaseGenerator:extend(class_name)
    local new_class = setmetatable({}, { __index = self })
    new_class.__index = new_class
    new_class.class_name = class_name
    return new_class
end

--- Get template context with common variables
--- @return table<string, any> context Template variables
function BaseGenerator:get_template_context()
    local context = {
        name = self.name,
        class_name = StringUtils.camelize(self.name),
        table_name = StringUtils.tableize(self.name),
        singular_name = StringUtils.singularize(self.name),
        plural_name = StringUtils.pluralize(self.name),
        underscore_name = StringUtils.underscore(self.name),
        constant_name = StringUtils.constantize(self.name),
        human_name = StringUtils.humanize(self.name)
    }
    
    -- Add options to context
    for key, value in pairs(self.options) do
        context[key] = value
    end
    
    return context
end

--- Create directory if it doesn't exist
--- @param path string Directory path to create
--- @return nil
function BaseGenerator:create_directory(path)
    if not FileUtils.exists(path) then
        local success, err = FileUtils.mkdir_p(path)
        if not success then
            error("Failed to create directory: " .. path .. " (" .. tostring(err) .. ")")
        end
        
        table.insert(self.directories_created, path)
        print("      create  " .. path)
    end
end

--- Generate file from template
--- @param file_path string Path where file should be created
--- @param template_name string Name of template to use
--- @param context table<string, any>? Template context (uses default if nil)
--- @return boolean success True if file was created
function BaseGenerator:create_file(file_path, template_name, context)
    context = context or self:get_template_context()
    
    -- Create directory if needed
    local dir = file_path:match("(.+)/[^/]+$")
    if dir then
        self:create_directory(dir)
    end
    
    -- Check if file already exists
    if FileUtils.exists(file_path) then
        if not self.options.force then
            print("       exist  " .. file_path)
            return false
        else
            print("       force  " .. file_path)
        end
    end
    
    -- Render template
    local content, err = TemplateEngine.render_builtin(template_name, context)
    if not content then
        error("Failed to render template " .. template_name .. ": " .. tostring(err))
    end
    
    -- Write file
    local success, write_err = FileUtils.write_file(file_path, content)
    if not success then
        error("Failed to write file " .. file_path .. ": " .. tostring(write_err))
    end
    
    table.insert(self.files_created, file_path)
    print("      create  " .. file_path)
    return true
end

--- Create file with direct content (no template)
--- @param file_path string Path where file should be created
--- @param content string File content
--- @return boolean success True if file was created
function BaseGenerator:create_file_with_content(file_path, content)
    -- Create directory if needed
    local dir = file_path:match("(.+)/[^/]+$")
    if dir then
        self:create_directory(dir)
    end
    
    -- Check if file already exists
    if FileUtils.exists(file_path) then
        if not self.options.force then
            print("       exist  " .. file_path)
            return false
        else
            print("       force  " .. file_path)
        end
    end
    
    -- Write file
    local success, err = FileUtils.write_file(file_path, content)
    if not success then
        error("Failed to write file " .. file_path .. ": " .. tostring(err))
    end
    
    table.insert(self.files_created, file_path)
    print("      create  " .. file_path)
    return true
end

-- Copy file from source to destination
function BaseGenerator:copy_file(src_path, dest_path)
    -- Create directory if needed
    local dir = dest_path:match("(.+)/[^/]+$")
    if dir then
        self:create_directory(dir)
    end
    
    -- Check if file already exists
    if FileUtils.exists(dest_path) then
        if not self.options.force then
            print("       exist  " .. dest_path)
            return false
        else
            print("       force  " .. dest_path)
        end
    end
    
    -- Copy file
    local success, err = FileUtils.copy_file(src_path, dest_path)
    if not success then
        error("Failed to copy file " .. src_path .. " to " .. dest_path .. ": " .. tostring(err))
    end
    
    table.insert(self.files_created, dest_path)
    print("      create  " .. dest_path)
    return true
end

-- Add route to routes file
function BaseGenerator:add_route(route_declaration)
    local routes_file = "config/routes.lua"
    
    if not FileUtils.exists(routes_file) then
        print("Warning: routes file not found at " .. routes_file)
        return false
    end
    
    local content, err = FileUtils.read_file(routes_file)
    if not content then
        print("Warning: failed to read routes file: " .. tostring(err))
        return false
    end
    
    -- Check if route already exists
    if content:find(route_declaration, 1, true) then
        print("       exist  route: " .. route_declaration)
        return false
    end
    
    -- Add route before the return statement
    local new_content = content:gsub("(return%s+router)", route_declaration .. "\n\n%1")
    
    local success, write_err = FileUtils.write_file(routes_file, new_content)
    if not success then
        print("Warning: failed to update routes file: " .. tostring(write_err))
        return false
    end
    
    print("       route  " .. route_declaration)
    return true
end

-- Show summary of generated files
function BaseGenerator:show_summary()
    if #self.files_created > 0 or #self.directories_created > 0 then
        print("\nGenerated:")
        
        for _, dir in ipairs(self.directories_created) do
            print("  📁 " .. dir)
        end
        
        for _, file in ipairs(self.files_created) do
            print("  📄 " .. file)
        end
    end
end

--- Validate generator arguments
--- @return boolean valid True if validation passes
function BaseGenerator:validate()
    if not self.name or self.name == "" then
        error("Generator name is required")
    end
    
    -- Check for valid identifier
    if not self.name:match("^[a-zA-Z_][a-zA-Z0-9_]*$") then
        error("Generator name must be a valid identifier: " .. self.name)
    end
    
    return true
end

--- Generate file from template
--- @param template_path string Path to template file relative to templates directory
--- @param output_path string Output file path
--- @param variables table Template variables for substitution
--- @return boolean success True if file was generated successfully
function BaseGenerator:generate_from_template(template_path, output_path, variables)
    -- Get full template path
    local full_template_path = TemplateEngine.get_template_path(template_path)
    
    -- Load template
    local template_content = TemplateEngine.load_template(full_template_path)
    if not template_content then
        print("Error: Template not found: " .. template_path)
        print("Looked for: " .. full_template_path)
        return false
    end
    
    -- Render template with variables
    local rendered_content = TemplateEngine.render(template_content, variables)
    
    -- Create output directory if needed
    local output_dir = output_path:match("^(.+)/[^/]+$")
    if output_dir then
        self:create_directory(output_dir)
    end
    
    -- Write file
    return self:create_file_with_content(output_path, rendered_content)
end

--- Main generation method (to be overridden by subclasses)
--- @return nil
function BaseGenerator:generate()
    self:validate()
    print("Running " .. (self.class_name or "BaseGenerator") .. " for " .. self.name)
    
    -- Subclasses should override this method
    error("generate() method must be implemented by subclass")
end

--- Run the generator with error handling
--- @return boolean success True if generation completed successfully
function BaseGenerator:run()
    local success, err = pcall(function()
        self:generate()
    end)
    
    if success then
        self:show_summary()
        return true
    else
        print("Error: " .. tostring(err))
        return false
    end
end

return BaseGenerator