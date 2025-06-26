-- Template engine for code generation
local function safe_require(module_name, fallback_name)
    local ok, result = pcall(require, module_name)
    if ok then
        return result
    else
        return require(fallback_name)
    end
end

local FileUtils = safe_require("controle.utils.file_utils", "utils.file_utils")

--- @class TemplateEngine
--- @field load_template function Load template from file
--- @field substitute_variables function Replace variables in template
--- @field process_conditionals function Handle if/unless blocks
--- @field process_loops function Handle each loops
--- @field render function Main render function
--- @field render_file function Render template from file
--- @field get_template_path function Get template path
--- @field render_builtin function Render built-in template
--- @field indent function Create indented content
--- @field list_items function Create list of items
--- @field clear_cache function Clear template cache
local TemplateEngine = {}

-- Template cache to avoid re-reading files
local template_cache = {}

--- Load template from file with caching
--- @param template_path string Path to template file
--- @return string? content Template content or nil if failed
--- @return string? error Error message if failed
function TemplateEngine.load_template(template_path)
    if template_cache[template_path] then
        return template_cache[template_path]
    end
    
    local content, err = FileUtils.read_file(template_path)
    if not content then
        return nil, "Failed to load template: " .. tostring(err)
    end
    
    template_cache[template_path] = content
    return content
end

--- Simple variable substitution - replaces {{variable}} with values
--- @param template string Template content
--- @param context table<string, any> Variables to substitute
--- @return string result Template with variables substituted
function TemplateEngine.substitute_variables(template, context)
    local result = template
    
    for key, value in pairs(context) do
        local pattern = "{{%s*" .. key .. "%s*}}"
        result = result:gsub(pattern, tostring(value))
    end
    
    return result
end

-- Handle conditional blocks
-- {{#if condition}}content{{/if}}
function TemplateEngine.process_conditionals(template, context)
    local result = template
    
    -- Process if blocks
    result = result:gsub("{{#if%s+([^}]+)}}(.-){{/if}}", function(condition, content)
        local value = context[condition]
        if value and value ~= false and value ~= "" then
            return content
        else
            return ""
        end
    end)
    
    -- Process unless blocks
    result = result:gsub("{{#unless%s+([^}]+)}}(.-){{/unless}}", function(condition, content)
        local value = context[condition]
        if not value or value == false or value == "" then
            return content
        else
            return ""
        end
    end)
    
    return result
end

-- Handle loops
-- {{#each items}}{{name}}{{/each}}
function TemplateEngine.process_loops(template, context)
    local result = template
    
    result = result:gsub("{{#each%s+([^}]+)}}(.-){{/each}}", function(array_name, loop_content)
        local array = context[array_name]
        if not array or type(array) ~= "table" then
            return ""
        end
        
        local output = {}
        for i, item in ipairs(array) do
            local loop_context = {}
            
            -- Copy main context
            for k, v in pairs(context) do
                loop_context[k] = v
            end
            
            -- Add loop variables
            if type(item) == "table" then
                for k, v in pairs(item) do
                    loop_context[k] = v
                end
            else
                loop_context.item = item
            end
            
            loop_context.index = i
            loop_context.first = (i == 1)
            loop_context.last = (i == #array)
            
            local processed = TemplateEngine.substitute_variables(loop_content, loop_context)
            table.insert(output, processed)
        end
        
        return table.concat(output)
    end)
    
    return result
end

--- Main render function - processes all template directives
--- @param template string Template content
--- @param context table<string, any>? Variables and data for template
--- @return string result Rendered template
function TemplateEngine.render(template, context)
    context = context or {}
    
    -- Process template directives in order
    local result = template
    result = TemplateEngine.process_loops(result, context)
    result = TemplateEngine.process_conditionals(result, context)
    result = TemplateEngine.substitute_variables(result, context)
    
    return result
end

--- Render template from file
--- @param template_path string Path to template file
--- @param context table<string, any>? Variables for template
--- @return string? result Rendered template or nil if failed
--- @return string? error Error message if failed
function TemplateEngine.render_file(template_path, context)
    local template, err = TemplateEngine.load_template(template_path)
    if not template then
        return nil, err
    end
    
    return TemplateEngine.render(template, context)
end

-- Get template path relative to controle package
function TemplateEngine.get_template_path(template_name)
    -- Try to find the controle package directory
    local controle_path = package.path:match("([^;]+controle[^;]*)")
    if controle_path then
        local base_path = controle_path:gsub("/src/%?%.lua", "")
        return FileUtils.join_path(base_path, "src", "templates", template_name)
    end
    
    -- Fallback to relative path
    return FileUtils.join_path("templates", template_name)
end

-- Render built-in template
function TemplateEngine.render_builtin(template_name, context)
    local template_path = TemplateEngine.get_template_path(template_name)
    return TemplateEngine.render_file(template_path, context)
end

-- Helper function to create indented content
function TemplateEngine.indent(content, spaces)
    spaces = spaces or 4
    local indent_str = string.rep(" ", spaces)
    
    return content:gsub("([^\n]*)", function(line)
        if line:match("%S") then -- Only indent non-empty lines
            return indent_str .. line
        else
            return line
        end
    end)
end

-- Helper function to create a list of items
function TemplateEngine.list_items(items, format_func)
    format_func = format_func or tostring
    local formatted = {}
    
    for _, item in ipairs(items) do
        table.insert(formatted, format_func(item))
    end
    
    return formatted
end

-- Clear template cache (useful for development)
function TemplateEngine.clear_cache()
    template_cache = {}
end

return TemplateEngine