# Controle - CLI & Generators 🛠️

Controle is the command-line interface that provides project scaffolding, development tools, and code generators for Foguete.

## Features

- **Project Scaffolding** - `fog new` creates complete project structure
- **Development Server** - `fog server` with hot reload and Vite integration
- **Code Generators** - Generate controllers, models, and migrations
- **Database Migrations** - Version control for database schema
- **Build Tools** - Production bundling and deployment prep
- **Interactive Console** - REPL for debugging and testing

## Quick Start

```bash
# Create new project
fog new my_blog
cd my_blog

# Start development server
fog server

# Generate a controller
fog generate controller Posts

# Run migrations
fog migrate
```

## Available Commands

### Project Management
```bash
fog new <name>           # Create new Foguete project
fog server              # Start development server (port 3000)
fog build              # Build for production
fog console            # Interactive Lua REPL
```

### Code Generation
```bash
fog generate controller Users    # Generate controller
fog generate model User         # Generate model
fog generate migration CreateUsers  # Generate migration
fog generate scaffold Post      # Generate full CRUD scaffold
```

### Database
```bash
fog migrate             # Run pending migrations
fog migrate:rollback    # Rollback last migration
fog migrate:status      # Show migration status
fog migrate:reset       # Reset database
```

## Project Structure

When you run `fog new`, it creates:

```
my_app/
├── main.lua              # Application entry point
├── src/
│   ├── app/
│   │   ├── controllers/  # Request handlers
│   │   ├── models/       # Database models
│   │   └── views/        # Preact components
│   └── config/
│       └── environments.lua
├── db/
│   └── migrate/          # Database migrations
├── public/              # Static assets
├── spec/               # Tests
├── package.json        # Frontend dependencies
└── vite.config.js     # Vite configuration
```

## Configuration

Environment-specific settings in `src/config/environments.lua`:

```lua
return {
    development = {
        database = "db/development.sqlite3",
        ssr = false,
        hot_reload = true
    },
    
    production = {
        database = "db/production.sqlite3", 
        ssr = true,
        hot_reload = false
    }
}
```

## Custom Generators

Create custom generators in `lib/generators/`:

```lua
-- lib/generators/service.lua
local function generate(name, args)
    local template = [[
local {{name}}Service = {}

function {{name}}Service.perform(data)
    -- Service logic here
end

return {{name}}Service
]]
    
    render_template(template, { name = name })
end

return { generate = generate }
```

Register in your project:
```bash
fog generate service EmailSender
```
