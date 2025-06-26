-- Controller generator for Comando framework controllers
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
local FileUtils = safe_require("controle.utils.file_utils", "utils.file_utils")

--- @class ControllerGenerator : BaseGenerator
local ControllerGenerator = BaseGenerator:extend("ControllerGenerator")

--- Parse actions from command line arguments
--- @param actions table<number, string> Action names
--- @return table<number, string> Valid action names
function ControllerGenerator:parse_actions(actions)
    local valid_actions = {
        "index", "show", "new", "create", "edit", "update", "destroy"
    }
    
    if #actions == 0 then
        -- Default RESTful actions
        return valid_actions
    end
    
    local parsed_actions = {}
    for _, action in ipairs(actions) do
        if self:is_valid_action(action, valid_actions) then
            table.insert(parsed_actions, action)
        else
            print("Warning: Unknown action '" .. action .. "', skipping")
        end
    end
    
    return parsed_actions
end

--- Check if action is valid
--- @param action string Action name
--- @param valid_actions table<number, string> List of valid actions
--- @return boolean valid True if action is valid
function ControllerGenerator:is_valid_action(action, valid_actions)
    for _, valid_action in ipairs(valid_actions) do
        if action == valid_action then
            return true
        end
    end
    return false
end

--- Parse field definitions from command line arguments
--- @param fields table<number, string> Field definitions like "name:string", "age:integer"
--- @return table<number, table> Parsed field definitions
function ControllerGenerator:parse_fields(fields)
    local parsed_fields = {}
    
    for _, field_def in ipairs(fields) do
        local name, field_type = field_def:match("^([^:]+):(.+)$")
        if name and field_type then
            local field = {
                name = name,
                type = field_type,
                ts_type = self:lua_to_typescript_type(field_type)
            }
            table.insert(parsed_fields, field)
        end
    end
    
    return parsed_fields
end

--- Convert Lua type to TypeScript type
--- @param lua_type string Lua type (string, number, boolean, etc.)
--- @return string TypeScript type
function ControllerGenerator:lua_to_typescript_type(lua_type)
    local type_map = {
        string = "string",
        text = "string", 
        integer = "number",
        number = "number",
        float = "number",
        boolean = "boolean",
        datetime = "string",
        date = "string",
        time = "string"
    }
    
    return type_map[lua_type] or "string"
end

--- Generate view content based on fields
--- @param fields table<number, table> Parsed field definitions
--- @param singular_name string Singular model name
--- @return string, string, string, string, string interface_fields, table_headers, table_cells, detail_fields, form_fields
function ControllerGenerator:generate_view_content(fields, singular_name)
    local interface_parts = {"  id: number;"}
    local header_parts = {"                    <th scope=\"col\" className=\"px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider\">ID</th>"}
    local cell_parts = {"                      <td className=\"px-6 py-4 whitespace-nowrap text-sm text-gray-900\">{" .. singular_name .. ".id}</td>"}
    local detail_parts = {}
    local form_parts = {}
    
    -- Add ID field to details
    table.insert(detail_parts, [[              <div className="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt className="text-sm font-medium text-gray-500">ID</dt>
                <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">{]] .. singular_name .. [[.id}</dd>
              </div>]])
    
    -- Generate content for each field
    for _, field in ipairs(fields) do
        local field_name = field.name
        local field_type = field.ts_type
        local field_title = StringUtils.titleize(field_name)
        
        -- TypeScript interface
        table.insert(interface_parts, "  " .. field_name .. ": " .. field_type .. ";")
        
        -- Table header
        table.insert(header_parts, "                    <th scope=\"col\" className=\"px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider\">" .. field_title .. "</th>")
        
        -- Table cell
        local cell_content
        if field.type == "datetime" or field.type == "date" then
            cell_content = "{new Date(" .. singular_name .. "." .. field_name .. ").toLocaleDateString()}"
        elseif field.type == "boolean" then
            cell_content = "{" .. singular_name .. "." .. field_name .. " ? 'Yes' : 'No'}"
        else
            cell_content = "{" .. singular_name .. "." .. field_name .. "}"
        end
        table.insert(cell_parts, "                      <td className=\"px-6 py-4 whitespace-nowrap text-sm text-gray-900\">" .. cell_content .. "</td>")
        
        -- Detail field
        local detail_content
        if field.type == "datetime" or field.type == "date" then
            detail_content = "{new Date(" .. singular_name .. "." .. field_name .. ").toLocaleDateString()}"
        elseif field.type == "boolean" then
            detail_content = "{" .. singular_name .. "." .. field_name .. " ? 'Yes' : 'No'}"
        else
            detail_content = "{" .. singular_name .. "." .. field_name .. "}"
        end
        table.insert(detail_parts, [[              <div className="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt className="text-sm font-medium text-gray-500">]] .. field_title .. [[</dt>
                <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">]] .. detail_content .. [[</dd>
              </div>]])
        
        -- Form field
        local input_type = "text"
        if field.type == "integer" or field.type == "number" or field.type == "float" then
            input_type = "number"
        elseif field.type == "boolean" then
            input_type = "checkbox"
        elseif field.type == "date" then
            input_type = "date"
        elseif field.type == "datetime" then
            input_type = "datetime-local"
        elseif field.type == "text" then
            input_type = "textarea"
        end
        
        local form_field
        if input_type == "textarea" then
            form_field = [[                <div>
                  <label htmlFor="]] .. field_name .. [[" className="block text-sm font-medium text-gray-700">]] .. field_title .. [[</label>
                  <div className="mt-1">
                    <textarea
                      id="]] .. field_name .. [["
                      name="]] .. field_name .. [["
                      rows={3}
                      value={formData.]] .. field_name .. [[ || ''}
                      onChange={(e) => handleChange(']] .. field_name .. [[', e.target.value)}
                      className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                  </div>
                  {errors.]] .. field_name .. [[ && (
                    <p className="mt-2 text-sm text-red-600">{errors.]] .. field_name .. [[.join(', ')}</p>
                  )}
                </div>]]
        elseif input_type == "checkbox" then
            form_field = [[                <div className="flex items-center">
                  <input
                    id="]] .. field_name .. [["
                    name="]] .. field_name .. [["
                    type="checkbox"
                    checked={formData.]] .. field_name .. [[ || false}
                    onChange={(e) => handleChange(']] .. field_name .. [[', e.target.checked)}
                    className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                  />
                  <label htmlFor="]] .. field_name .. [[" className="ml-2 block text-sm text-gray-900">]] .. field_title .. [[</label>
                  {errors.]] .. field_name .. [[ && (
                    <p className="mt-2 text-sm text-red-600">{errors.]] .. field_name .. [[.join(', ')}</p>
                  )}
                </div>]]
        else
            form_field = [[                <div>
                  <label htmlFor="]] .. field_name .. [[" className="block text-sm font-medium text-gray-700">]] .. field_title .. [[</label>
                  <div className="mt-1">
                    <input
                      type="]] .. input_type .. [["
                      id="]] .. field_name .. [["
                      name="]] .. field_name .. [["
                      value={formData.]] .. field_name .. [[ || ''}
                      onChange={(e) => handleChange(']] .. field_name .. [[', e.target.value)}
                      className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                  </div>
                  {errors.]] .. field_name .. [[ && (
                    <p className="mt-2 text-sm text-red-600">{errors.]] .. field_name .. [[.join(', ')}</p>
                  )}
                </div>]]
        end
        table.insert(form_parts, form_field)
    end
    
    -- Add timestamps
    table.insert(interface_parts, "  created_at: string;")
    table.insert(interface_parts, "  updated_at: string;")
    
    table.insert(header_parts, "                    <th scope=\"col\" className=\"px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider\">Created</th>")
    table.insert(cell_parts, "                      <td className=\"px-6 py-4 whitespace-nowrap text-sm text-gray-500\">{new Date(" .. singular_name .. ".created_at).toLocaleDateString()}</td>")
    
    table.insert(detail_parts, [[              <div className="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt className="text-sm font-medium text-gray-500">Created At</dt>
                <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">{new Date(]] .. singular_name .. [[.created_at).toLocaleDateString()}</dd>
              </div>]])
    
    table.insert(detail_parts, [[              <div className="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt className="text-sm font-medium text-gray-500">Updated At</dt>
                <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">{new Date(]] .. singular_name .. [[.updated_at).toLocaleDateString()}</dd>
              </div>]])
    
    return table.concat(interface_parts, "\n"),
           table.concat(header_parts, "\n"),
           table.concat(cell_parts, "\n"),
           table.concat(detail_parts, "\n"),
           table.concat(form_parts, "\n")
end

--- Update main.tsx with new view imports
--- @param view_path string View path (e.g., "posts")
--- @param actions table<number, string> Generated actions
--- @return nil
function ControllerGenerator:update_main_tsx_imports(view_path, actions)
    local main_file = "app/main.tsx"
    
    -- Check if main.tsx exists
    if not FileUtils.exists(main_file) then
        print("Warning: " .. main_file .. " not found, skipping view registration")
        return
    end
    
    -- Read current main.tsx content
    local current_content, err = FileUtils.read_file(main_file)
    if not current_content then
        print("Warning: Could not read " .. main_file .. ": " .. (err or "unknown error"))
        return
    end
    
    -- Generate import lines for each view
    local new_imports = {}
    
    if self:is_valid_action("index", actions) then
        table.insert(new_imports, '  "' .. view_path .. '/index": () => import("./views/' .. view_path .. '/index.tsx"),')
    end
    
    if self:is_valid_action("show", actions) then
        table.insert(new_imports, '  "' .. view_path .. '/show": () => import("./views/' .. view_path .. '/show.tsx"),')
    end
    
    if self:is_valid_action("new", actions) then
        table.insert(new_imports, '  "' .. view_path .. '/new": () => import("./views/' .. view_path .. '/form.tsx"),')
    end
    
    if self:is_valid_action("edit", actions) then
        table.insert(new_imports, '  "' .. view_path .. '/edit": () => import("./views/' .. view_path .. '/form.tsx"),')
    end
    
    if #new_imports == 0 then
        return
    end
    
    -- Find the pages object and add new imports
    local pages_start = string.find(current_content, "const pages = {")
    if not pages_start then
        print("Warning: Could not find pages object in " .. main_file)
        return
    end
    
    -- Find the closing brace of the pages object
    local pages_end = string.find(current_content, "};", pages_start)
    if not pages_end then
        print("Warning: Could not find end of pages object in " .. main_file)
        return
    end
    
    -- Check if imports already exist
    local imports_to_add = {}
    for _, import_line in ipairs(new_imports) do
        if not string.find(current_content, import_line, 1, true) then
            table.insert(imports_to_add, import_line)
        end
    end
    
    if #imports_to_add == 0 then
        print("✓ Views already registered in " .. main_file)
        return
    end
    
    -- Insert new imports before the closing brace
    local before_closing = string.sub(current_content, 1, pages_end - 1)
    local after_closing = string.sub(current_content, pages_end)
    
    local new_content = before_closing .. "\n" .. table.concat(imports_to_add, "\n") .. "\n" .. after_closing
    
    -- Write the updated content
    local success, write_err = FileUtils.write_file(main_file, new_content)
    if success then
        print("✓ Added view imports to " .. main_file)
    else
        print("✗ Failed to update " .. main_file .. ": " .. (write_err or "unknown error"))
    end
end

--- Generate test attributes for controller specs
--- @param model_name string Model name
--- @return string Test attributes
function ControllerGenerator:generate_test_attributes(model_name)
    -- This would ideally read from the model file to get actual fields
    -- For now, we'll use generic test attributes
    return '{ name = "Test Name" }'
end

--- Generate invalid attributes for controller specs
--- @param model_name string Model name
--- @return string Invalid attributes
function ControllerGenerator:generate_invalid_attributes(model_name)
    return '{ name = "" }'  -- Empty name is typically invalid
end

--- Generate update attributes for controller specs
--- @param model_name string Model name
--- @return string Update attributes
function ControllerGenerator:generate_update_attributes(model_name)
    return '{ name = "Updated Name" }'
end

--- Generate find attributes for controller specs
--- @param model_name string Model name
--- @return string Find attributes
function ControllerGenerator:generate_find_attributes(model_name)
    return '{ name = "Test Name" }'
end

--- Run the controller generator
--- @param parsed_args table Parsed command line arguments
--- @return boolean success True if generation succeeded
function ControllerGenerator.run(parsed_args)
    local generator = ControllerGenerator:new("controller", parsed_args.options)
    
    -- Get controller name
    local controller_name = parsed_args.subcommand
    if not controller_name then
        print("Error: Controller name is required")
        print("Usage: fog generate controller <ControllerName> [action1 action2 ...]")
        print("Example: fog generate controller Users index show create")
        return false
    end
    
    -- Parse actions (check if actions are provided separately, otherwise use args)
    local actions
    if parsed_args.actions then
        actions = generator:parse_actions(parsed_args.actions)
    else
        actions = generator:parse_actions(parsed_args.args)
    end
    
    -- Generate template variables
    local class_name = StringUtils.camelize(controller_name) .. "Controller"
    local file_name = StringUtils.underscore(controller_name) .. "_controller"
    local model_name = StringUtils.singularize(StringUtils.camelize(controller_name))
    local model_file = StringUtils.underscore(StringUtils.singularize(controller_name))
    local route_path = StringUtils.underscore(controller_name)
    local view_path = StringUtils.underscore(controller_name)
    local singular_name = StringUtils.underscore(StringUtils.singularize(controller_name))
    local plural_name = StringUtils.underscore(controller_name)
    local table_name = StringUtils.pluralize(StringUtils.underscore(StringUtils.singularize(controller_name)))
    
    local template_vars = {
        class_name = class_name,
        file_name = file_name,
        model_name = model_name,
        model_file = model_file,
        route_path = route_path,
        view_path = view_path,
        singular_name = singular_name,
        plural_name = plural_name,
        table_name = table_name,
        test_attributes = generator:generate_test_attributes(model_name),
        invalid_attributes = generator:generate_invalid_attributes(model_name),
        update_attributes = generator:generate_update_attributes(model_name),
        test_find_attributes = generator:generate_find_attributes(model_name)
    }
    
    -- Generate controller file
    local controller_path = "app/controllers/" .. file_name .. ".lua"
    generator:generate_from_template("controller/controller.lua", controller_path, template_vars)
    
    -- Generate spec file
    local spec_path = "spec/controllers/" .. file_name .. "_spec.lua"
    generator:generate_from_template("controller/spec.lua", spec_path, template_vars)
    
    -- Generate view files for Orbita SPA
    local views_dir = "app/views/" .. view_path
    generator:create_directory(views_dir)
    
    -- Parse fields from command line arguments (if provided)
    local fields
    if parsed_args.actions then
        -- If actions are provided separately, args contains field definitions
        fields = generator:parse_fields(parsed_args.args or {})
    else
        -- If no separate actions, args contains actions, so no fields
        fields = {}
    end
    
    -- Generate dynamic content based on fields
    local interface_fields, table_headers, table_cells, detail_fields, form_fields = 
        generator:generate_view_content(fields, singular_name)
    
    local view_vars = {
        class_name = model_name,
        singular_name = singular_name,
        plural_name = plural_name,
        route_path = route_path,
        kebab_name = StringUtils.dasherize(singular_name),
        title_name = StringUtils.titleize(plural_name),
        singular_title = StringUtils.titleize(singular_name),
        plural_title = StringUtils.titleize(plural_name),
        interface_fields = interface_fields,
        table_headers = table_headers,
        table_cells = table_cells,
        detail_fields = detail_fields,
        form_fields = form_fields
    }
    
    -- Generate view files if actions include them
    if generator:is_valid_action("index", actions) then
        generator:generate_from_template("view/index.tsx", views_dir .. "/index.tsx", view_vars)
    end
    
    if generator:is_valid_action("show", actions) then
        generator:generate_from_template("view/show.tsx", views_dir .. "/show.tsx", view_vars)
    end
    
    if generator:is_valid_action("new", actions) or generator:is_valid_action("edit", actions) then
        generator:generate_from_template("view/form.tsx", views_dir .. "/form.tsx", view_vars)
    end
    
    -- Update main.tsx with new view imports
    generator:update_main_tsx_imports(view_path, actions)
    
    generator:show_summary()
    
    print("\nNext steps:")
    print("  1. Add routes to config/routes.lua:")
    print("     router:resources(\"" .. route_path .. "\", " .. class_name .. ")")
    print("  2. Review the generated controller in " .. controller_path)
    print("  3. Customize the view components in " .. views_dir)
    print("  4. Run the tests: fog test controllers")
    
    return true
end

return ControllerGenerator