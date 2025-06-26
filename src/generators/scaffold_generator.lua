-- Scaffold generator - generates complete CRUD functionality
local function safe_require(module_name, fallback_name)
    local ok, result = pcall(require, module_name)
    if ok then
        return result
    else
        return require(fallback_name)
    end
end

local BaseGenerator = safe_require("controle.generators.base_generator", "generators.base_generator")
local ModelGenerator = safe_require("controle.generators.model_generator", "generators.model_generator")
local ControllerGenerator = safe_require("controle.generators.controller_generator", "generators.controller_generator")
local MigrationGenerator = safe_require("controle.generators.migration_generator", "generators.migration_generator")
local StringUtils = safe_require("controle.utils.string_utils", "utils.string_utils")
local FileUtils = safe_require("controle.utils.file_utils", "utils.file_utils")

--- @class ScaffoldGenerator : BaseGenerator
local ScaffoldGenerator = BaseGenerator:extend("ScaffoldGenerator")

--- Run the scaffold generator
--- @param parsed_args table Parsed command line arguments
--- @return boolean success True if generation succeeded
function ScaffoldGenerator.run(parsed_args)
    local generator = ScaffoldGenerator:new("scaffold", parsed_args.options)
    
    -- Get model name
    local model_name = parsed_args.subcommand
    if not model_name then
        print("Error: Model name is required")
        print("Usage: fog generate scaffold <ModelName> [field:type ...]")
        print("Example: fog generate scaffold Post title:string content:text published:boolean")
        return false
    end
    
    print("Generating scaffold for " .. model_name .. "...")
    print("This will create:")
    print("  - Model with validations")
    print("  - Controller with RESTful actions")
    print("  - Views (React components)")
    print("  - Database migration")
    print("  - Test files")
    print("")
    
    -- Generate model
    print("Generating model...")
    local model_args = {
        subcommand = model_name,
        args = parsed_args.args,
        options = parsed_args.options
    }
    
    if not ModelGenerator.run(model_args) then
        print("Error: Failed to generate model")
        return false
    end
    
    -- Generate controller
    print("\nGenerating controller...")
    local controller_name = StringUtils.pluralize(model_name)
    local controller_args = {
        subcommand = controller_name,
        args = {"index", "show", "new", "create", "edit", "update", "destroy"},
        options = parsed_args.options
    }
    
    if not ControllerGenerator.run(controller_args) then
        print("Error: Failed to generate controller")
        return false
    end
    
    -- Generate routes configuration
    print("\nGenerating routes...")
    generator:generate_routes_config(model_name, controller_name)
    generator:add_routes_to_config(model_name, controller_name)
    
    generator:show_summary()
    
    print("\n🎉 Scaffold generation completed!")
    print("\nNext steps:")
    print("  1. Add the route to config/routes.lua:")
    print("     local " .. StringUtils.camelize(controller_name) .. "Controller = require(\"app.controllers." .. StringUtils.underscore(controller_name) .. "_controller\")")
    print("     router:resources(\"" .. StringUtils.underscore(controller_name) .. "\", " .. StringUtils.camelize(controller_name) .. "Controller)")
    print("  2. Run the migration: fog db:migrate")
    print("  3. Start the server: fog server")
    print("  4. Visit http://localhost:3000/" .. StringUtils.underscore(controller_name))
    print("  5. Run the tests: fog test")
    
    return true
end

--- Generate routes configuration snippet
--- @param model_name string Model name
--- @param controller_name string Controller name
--- @return nil
function ScaffoldGenerator:generate_routes_config(model_name, controller_name)
    local route_path = StringUtils.underscore(controller_name)
    local controller_class = StringUtils.camelize(controller_name) .. "Controller"
    local controller_file = StringUtils.underscore(controller_name) .. "_controller"
    
    local routes_snippet = string.format([[
-- Add this to your config/routes.lua file:
local %s = require("app.controllers.%s")
router:resources("%s", %s)

-- This will create the following routes:
-- GET    /%s           -> %s:index()
-- GET    /%s/new       -> %s:new()
-- POST   /%s           -> %s:create()
-- GET    /%s/:id       -> %s:show()
-- GET    /%s/:id/edit  -> %s:edit()
-- PUT    /%s/:id       -> %s:update()
-- DELETE /%s/:id       -> %s:destroy()
]], 
        controller_class, controller_file, route_path, controller_class,
        route_path, controller_class,
        route_path, controller_class,
        route_path, controller_class,
        route_path, controller_class,
        route_path, controller_class,
        route_path, controller_class,
        route_path, controller_class
    )
    
    -- Write routes snippet to a temporary file for reference
    local routes_file = "tmp/routes_" .. route_path .. ".txt"
    self:create_file_with_content(routes_file, routes_snippet)
    
    print("Routes configuration saved to " .. routes_file)
end

--- Add routes to the main routes.lua configuration file
--- @param model_name string Model name
--- @param controller_name string Controller name
--- @return nil
function ScaffoldGenerator:add_routes_to_config(model_name, controller_name)
    local routes_file = "config/routes.lua"
    local controller_class = StringUtils.camelize(controller_name) .. "Controller"
    local controller_file = StringUtils.underscore(controller_name) .. "_controller"
    local route_path = StringUtils.underscore(controller_name)
    
    -- Check if routes file exists
    if not FileUtils.exists(routes_file) then
        print("Warning: " .. routes_file .. " not found, skipping automatic route addition")
        return
    end
    
    -- Read current routes file
    local current_content, err = FileUtils.read_file(routes_file)
    if not current_content then
        print("Warning: Could not read " .. routes_file .. ": " .. (err or "unknown error"))
        return
    end
    
    -- Check if routes already exist
    if string.find(current_content, controller_class) then
        print("Routes for " .. controller_class .. " already exist, skipping")
        return
    end
    
    -- Generate the route code to add
    local route_code = string.format([[
	-- %s RESTful routes
	local %s = require("app.controllers.%s")
	local %s_actions = {
		index = function(request)
			local controller = %s:new(request)
			return controller:index()
		end,
		show = function(request)
			local controller = %s:new(request)
			return controller:show()
		end,
		new_action = function(request)
			local controller = %s:new(request)
			return controller:new_action()
		end,
		create = function(request)
			local controller = %s:new(request)
			return controller:create()
		end,
		edit = function(request)
			local controller = %s:new(request)
			return controller:edit()
		end,
		update = function(request)
			local controller = %s:new(request)
			return controller:update()
		end,
		destroy = function(request)
			local controller = %s:new(request)
			return controller:destroy()
		end
	}
	
	router:resources("%s", %s_actions)
]], 
        controller_class, controller_class, controller_file, route_path,
        controller_class, controller_class, controller_class, controller_class,
        controller_class, controller_class, controller_class, route_path, route_path)
    
    -- Find the insertion point (before the final comment section)
    local insertion_point = string.find(current_content, "\t%-%- Add your routes here")
    if insertion_point then
        -- Insert before the comment
        local new_content = string.sub(current_content, 1, insertion_point - 1) .. 
                           route_code .. "\n" .. 
                           string.sub(current_content, insertion_point)
        
        -- Write the updated content
        local success, write_err = FileUtils.write_file(routes_file, new_content)
        if success then
            print("✓ Added routes for " .. controller_class .. " to " .. routes_file)
        else
            print("✗ Failed to write routes to " .. routes_file .. ": " .. (write_err or "unknown error"))
        end
    else
        print("Warning: Could not find insertion point in " .. routes_file)
        print("Please manually add the routes using the generated snippet")
    end
end

return ScaffoldGenerator