-- fog new command - Create new Foguete application
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

--- @class NewCommand
--- @field show_help function Show help for new command
--- @field create_directories function Create application directory structure
--- @field create_server_file function Create main server file
--- @field create_config_files function Create configuration files
--- @field create_base_controller function Create base controller
--- @field create_package_json function Create package.json
--- @field create_essential_files function Create other essential files
--- @field run function Main command execution
local NewCommand = {}

--- Show help for new command
--- @return nil
function NewCommand.show_help()
	print([[
Usage: fog new <app_name> [options]

Create a new Foguete application with the specified name.

Arguments:
    app_name    Name of the application to create

Options:
    --force     Overwrite existing directory
    --help      Show this help message

Examples:
    fog new my_blog
    fog new ecommerce_site --force
]])
end

--- Create application directory structure
--- @param app_name string Name of the application
--- @return nil
function NewCommand.create_directories(app_name)
	local directories = {
		app_name,
		app_name .. "/app",
		app_name .. "/app/controllers",
		app_name .. "/app/models",
		app_name .. "/app/views",
		app_name .. "/app/views/home",
		app_name .. "/config",
		app_name .. "/config/environments",
		app_name .. "/db",
		app_name .. "/db/migrate",
		app_name .. "/public",
		app_name .. "/public/assets",
		app_name .. "/spec",
		app_name .. "/spec/models",
		app_name .. "/spec/controllers",
		app_name .. "/tmp",
	}

	for _, dir in ipairs(directories) do
		local success, err = FileUtils.mkdir_p(dir)
		if not success then
			error("Failed to create directory " .. dir .. ": " .. tostring(err))
		end
		print("      create  " .. dir)
	end
end

-- Create main server file
function NewCommand.create_server_file(app_name)
	local content = [[#!/usr/bin/env lua

-- {{app_name}} - Foguete Application Server
local motor = require("motor")
local rota = require("rota")
local carga = require("carga")
local orbita = require("orbita")

-- Load application configuration
require("config.application")

-- Initialize database
carga.Database.connect("db/{{underscore_name}}.db")

-- Configure Orbita
orbita.configure({
    root_template = "app",
    asset_version = "1.0.0",
    app_js_path = "/app/main.tsx"
})

-- Create router
local router = rota.new()

-- Load routes
require("config.routes")(router)

-- Request handler
local function handle_request(request)
    print("📥 " .. request.method .. " " .. request.path)
    
    local response = router:dispatch(request)
    
    if not response then
        return {
            status = 404,
            headers = { ["Content-Type"] = "text/html" },
            body = "<h1>404 - Page Not Found</h1><p>Path: " .. request.path .. "</p>"
        }
    end
    
    return response
end

-- Start server
local port = tonumber(os.getenv("PORT")) or 8080
local host = os.getenv("HOST") or "127.0.0.1"

print("🚀 Starting {{app_name}} server...")
print("🌐 Visit: http://" .. host .. ":" .. port)

motor.serve({
    host = host,
    port = port
}, handle_request)
]]

	local context = {
		app_name = app_name,
		underscore_name = StringUtils.underscore(app_name),
	}

	local rendered = TemplateEngine.render(content, context)

	local success, err = FileUtils.write_file(app_name .. "/server.lua", rendered)
	if not success then
		error("Failed to create server.lua: " .. tostring(err))
	end

	print("      create  " .. app_name .. "/server.lua")
end

-- Create application configuration
function NewCommand.create_config_files(app_name)
	-- config/application.lua
	local app_config = [[-- {{app_name}} Application Configuration

local config = {
    app_name = "{{app_name}}",
    environment = os.getenv("FOGUETE_ENV") or "development",
    
    -- Database configuration
    database = {
        path = "db/{{underscore_name}}.db"
    },
    
    -- Server configuration
    server = {
        host = "127.0.0.1",
        port = 8080
    },
    
    -- Asset configuration
    assets = {
        compile = true,
        digest = false
    }
}

-- Environment-specific configuration
local env_config_path = "config.environments." .. config.environment
local ok, env_config = pcall(require, env_config_path)
if ok then
    for key, value in pairs(env_config) do
        config[key] = value
    end
end

return config
]]

	-- config/routes.lua
	local routes_config = [[-- {{app_name}} Routes Configuration

return function(router)
    -- Root route
    router:get("/", function(request)
        local ApplicationController = require("app.controllers.application_controller")
        local controller = ApplicationController:new(request)
        return controller:index()
    end)
    
    -- Demo greeting route
    router:post("/greet", function(request)
        local ApplicationController = require("app.controllers.application_controller")
        local controller = ApplicationController:new(request)
        return controller:greet()
    end)
    
    -- Add your routes here
    -- Example:
    -- local users_controller = require("app.controllers.users_controller")
    -- router:resources("users", users_controller)
end
]]

	-- config/environments/development.lua
	local dev_config = [[-- Development Environment Configuration

return {
    -- Enable debug logging
    debug = true,
    
    -- Asset configuration for development
    assets = {
        compile = false,
        digest = false
    },
    
    -- Database configuration
    database = {
        path = "db/{{underscore_name}}_development.db"
    }
}
]]

	-- config/environments/production.lua
	local prod_config = [[-- Production Environment Configuration

return {
    -- Disable debug logging
    debug = false,
    
    -- Asset configuration for production
    assets = {
        compile = true,
        digest = true
    },
    
    -- Database configuration
    database = {
        path = "db/{{underscore_name}}_production.db"
    },
    
    -- Server configuration
    server = {
        host = "0.0.0.0",
        port = tonumber(os.getenv("PORT")) or 8080
    }
}
]]

	local context = {
		app_name = app_name,
		underscore_name = StringUtils.underscore(app_name),
	}

	local files = {
		{ path = "config/application.lua", content = app_config },
		{ path = "config/routes.lua", content = routes_config },
		{ path = "config/environments/development.lua", content = dev_config },
		{ path = "config/environments/production.lua", content = prod_config },
	}

	for _, file in ipairs(files) do
		local rendered = TemplateEngine.render(file.content, context)
		local file_path = app_name .. "/" .. file.path

		local success, err = FileUtils.write_file(file_path, rendered)
		if not success then
			error("Failed to create " .. file.path .. ": " .. tostring(err))
		end

		print("      create  " .. file_path)
	end
end

-- Create base controller
function NewCommand.create_base_controller(app_name)
	local content = [[-- Application Base Controller
local BaseController = require("comando")
local orbita = require("orbita")

local ApplicationController = {}
ApplicationController.__index = ApplicationController
setmetatable(ApplicationController, BaseController)

-- Extend BaseController with Orbita methods
ApplicationController = orbita.extend_controller(ApplicationController)

function ApplicationController:new(request)
    local controller = BaseController:new(request)
    setmetatable(controller, self)
    return controller
end

-- Default index action
function ApplicationController:index()
    return self:render_orbita("home/index", {
        title = "Welcome to {{app_name}}",
        message = "Your Foguete application is running!"
    })
end

-- Demo greeting action
function ApplicationController:greet()
    local data = self:request_data()
    local name = data.name or "Anon"
 
    return self:render_orbita("home/index", {
        title = "Welcome to {{app_name}}",
        message = "Your Foguete application is running!",
        flash = {
            success = "Hello " .. name .. "! 🚀 Your Lua server is working perfectly!"
        }
    })
end

return ApplicationController
]]

	local context = {
		app_name = app_name,
	}

	local rendered = TemplateEngine.render(content, context)
	local file_path = app_name .. "/app/controllers/application_controller.lua"

	local success, err = FileUtils.write_file(file_path, rendered)
	if not success then
		error("Failed to create application_controller.lua: " .. tostring(err))
	end

	print("      create  " .. file_path)
end

-- Create package.json for frontend dependencies
function NewCommand.create_package_json(app_name)
	local content = [[{
  "name": "{{underscore_name}}",
  "version": "1.0.0",
  "description": "{{app_name}} - Foguete Application",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "server": "lua server.lua"
  },
  "dependencies": {
    "@foguete/orbita": "^0.0.1",
    "preact": "^10.19.0"
  },
  "devDependencies": {
    "@preact/preset-vite": "^2.7.0",
    "@tailwindcss/forms": "^0.5.10",
    "@tailwindcss/typography": "^0.5.16",
    "@tailwindcss/vite": "^4.1.6",
    "eslint": "^8.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint-config-preact": "^1.3.0",
    "tailwindcss": "^4.1.6",
    "typescript": "^5.0.0",
    "vite": "^5.0.0"
  }
}
]]

	local context = {
		app_name = app_name,
		underscore_name = StringUtils.underscore(app_name),
	}

	local rendered = TemplateEngine.render(content, context)
	local file_path = app_name .. "/package.json"

	local success, err = FileUtils.write_file(file_path, rendered)
	if not success then
		error("Failed to create package.json: " .. tostring(err))
	end

	print("      create  " .. file_path)
end

-- Create other essential files
function NewCommand.create_essential_files(app_name)
	-- .gitignore
	local gitignore = [[# Lua
*.lua~
*.luac

# Database files
*.db
*.sqlite3
*.db-shm
*.db-wal

# Node modules
node_modules/

# Build artifacts
dist/
build/
public/assets/*.js
public/assets/*.css

# Environment files
.env
.env.local

# Logs
*.log

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Temporary files
tmp/
*.tmp
]]

	-- README.md
	local readme = [[# {{app_name}}

A Foguete framework application.

## Getting Started

### Prerequisites

- Lua 5.1+
- Node.js 18+
- LuaRocks

### Installation

1. Install Lua dependencies:
```bash
luarocks install motor
luarocks install rota
luarocks install comando
luarocks install carga
luarocks install orbita
```

2. Install Node.js dependencies:
```bash
npm install
```

3. Build frontend assets:
```bash
npm run build
```

### Development

Start the development server:
```bash
lua server.lua
```

Or use the npm script:
```bash
npm run server
```

For frontend development with hot reload:
```bash
npm run dev
```

### Database

Create and migrate the database:
```bash
fog db:create
fog db:migrate
```

### Testing

Run tests:
```bash
fog test
```

## Project Structure

```
{{underscore_name}}/
├── app/
│   ├── controllers/     # Comando controllers
│   ├── models/         # Carga models
│   └── views/          # Orbita views
├── config/             # Application configuration
├── db/                 # Database files and migrations
├── public/             # Static assets
├── spec/               # Test files
└── server.lua          # Main server file
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License
]]

	local context = {
		app_name = app_name,
		underscore_name = StringUtils.underscore(app_name),
	}

	-- Vite configuration
	local vite_config = TemplateEngine.load_template(TemplateEngine.get_template_path("application/vite.config.js"))

	-- TypeScript configuration
	local tsconfig = TemplateEngine.load_template(TemplateEngine.get_template_path("application/tsconfig.json"))

	-- Main entry point
	local main_tsx = TemplateEngine.load_template(TemplateEngine.get_template_path("application/main.tsx"))

	-- Home view
	local home_index = TemplateEngine.load_template(TemplateEngine.get_template_path("application/home_index.tsx"))

	-- ESLint configuration
	local eslintrc = TemplateEngine.load_template(TemplateEngine.get_template_path("application/eslintrc.json"))

	-- CSS file
	local app_css = TemplateEngine.load_template(TemplateEngine.get_template_path("application/app.css"))

	-- index.html
	local index_html = [[<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{{app_name}}</title>
    <script>
      // This will be populated by the backend
      window.__ORBITA_PAGE__ = null;
    </script>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/app/main.tsx"></script>
  </body>
</html>]]

	local files = {
		{ path = ".gitignore", content = gitignore },
		{ path = "README.md", content = readme },
		{ path = "index.html", content = index_html },
		{ path = "vite.config.js", content = vite_config or "" },
		{ path = "tsconfig.json", content = tsconfig or "" },
		{ path = "app/main.tsx", content = main_tsx or "" },
		{ path = "app/app.css", content = app_css or "" },
		{ path = "app/views/home/index.tsx", content = home_index or "" },
		{ path = ".eslintrc.json", content = eslintrc or "" },
	}

	for _, file in ipairs(files) do
		local rendered = TemplateEngine.render(file.content, context)
		local file_path = app_name .. "/" .. file.path

		local success, err = FileUtils.write_file(file_path, rendered)
		if not success then
			error("Failed to create " .. file.path .. ": " .. tostring(err))
		end

		print("      create  " .. file_path)
	end
end

--- Main command execution
--- @param parsed_args table Parsed command line arguments
--- @return boolean success True if command executed successfully
function NewCommand.run(parsed_args)
	if parsed_args.options.help then
		NewCommand.show_help()
		return true
	end

	local app_name = parsed_args.subcommand
	if not app_name then
		print("Error: Application name is required")
		NewCommand.show_help()
		return false
	end

	-- Validate app name
	if not app_name:match("^[a-zA-Z_][a-zA-Z0-9_]*$") then
		print("Error: Application name must be a valid identifier")
		return false
	end

	-- Check if directory already exists
	if FileUtils.exists(app_name) then
		if not parsed_args.options.force then
			print("Error: Directory '" .. app_name .. "' already exists")
			print("Use --force to overwrite")
			return false
		else
			print("Warning: Overwriting existing directory '" .. app_name .. "'")
		end
	end

	print("Creating new Foguete application: " .. app_name)

	-- Create application structure
	NewCommand.create_directories(app_name)
	NewCommand.create_server_file(app_name)
	NewCommand.create_config_files(app_name)
	NewCommand.create_base_controller(app_name)
	NewCommand.create_package_json(app_name)
	NewCommand.create_essential_files(app_name)

	print("\n✅ Application '" .. app_name .. "' created successfully!")
	print("\nNext steps:")
	print("  cd " .. app_name)
	print("  npm install")
	print("  npm run build")
	print("  lua server.lua")

	return true
end

return NewCommand
