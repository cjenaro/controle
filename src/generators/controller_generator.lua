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
    
    -- Parse actions
    local actions = generator:parse_actions(parsed_args.args)
    
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
    
    -- Generate TypeScript interface fields (basic example)
    local interface_fields = [[  id: number;
  name: string;
  created_at: string;
  updated_at: string;]]
    
    local table_headers = [[                  <th>ID</th>
                  <th>Name</th>
                  <th>Created</th>]]
    
    local table_cells = [[                    <td>{user.id}</td>
                    <td>{user.name}</td>
                    <td>{new Date(user.created_at).toLocaleDateString()}</td>]]
    
    local detail_fields = [[        <div className="field">
          <label>ID:</label>
          <span>{user.id}</span>
        </div>
        <div className="field">
          <label>Name:</label>
          <span>{user.name}</span>
        </div>
        <div className="field">
          <label>Created:</label>
          <span>{new Date(user.created_at).toLocaleDateString()}</span>
        </div>]]
    
    local form_fields = [[        <div className="form-group">
          <label htmlFor="name">Name</label>
          <input
            type="text"
            id="name"
            value={formData.name || ''}
            onChange={(e) => handleChange('name', e.target.value)}
            className={errors.name ? 'form-control is-invalid' : 'form-control'}
          />
          {errors.name && (
            <div className="invalid-feedback">
              {errors.name.join(', ')}
            </div>
          )}
        </div>]]
    
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