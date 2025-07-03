-- fog db command - Database management
local function safe_require(module_name, fallback_name)
    local ok, result = pcall(require, module_name)
    if ok then
        return result
    else
        return require(fallback_name)
    end
end

local FileUtils = safe_require("controle.utils.file_utils", "utils.file_utils")

local DbCommand = {}

function DbCommand.show_help()
    print([[
Usage: fog db:<action> [options]

Database management commands for your Foguete application.

Actions:
    create      Create the database file
    migrate     Run pending migrations
    rollback    Rollback the last migration
    seed        Run database seeds
    reset       Drop, create, migrate, and seed
    status      Show migration status

Options:
    --step <n>  Number of migrations to rollback (for rollback)
    --help      Show this help message

Examples:
    fog db:create
    fog db:migrate
    fog db:rollback
    fog db:rollback --step 3
    fog db:seed
    fog db:reset
    fog db:status
]])
end

function DbCommand.get_database_path()
    -- Try to load application configuration
    local ok, config = pcall(require, "config.application")
    if ok and config.database and config.database.path then
        return config.database.path
    end
    
    -- Default path
    return "db/development.db"
end

function DbCommand.create_database()
    local db_path = DbCommand.get_database_path()
    
    -- Create db directory if it doesn't exist
    local db_dir = db_path:match("(.+)/[^/]+$")
    if db_dir then
        local success, err = FileUtils.mkdir_p(db_dir)
        if not success then
            print("Error: Failed to create database directory: " .. tostring(err))
            return false
        end
    end
    
    -- Initialize Carga and create database
    local ok, carga = pcall(require, "carga")
    if not ok then
        print("Error: Carga package not found. Please install it first.")
        return false
    end
    
    carga.Database.connect(db_path)
    print("Database created: " .. db_path)
    
    return true
end

function DbCommand.run_migrations()
    print("Running database migrations...")
    
    -- Initialize database
    if not DbCommand.create_database() then
        return false
    end
    
    -- Load Carga and Migration module
    local ok, carga = pcall(require, "carga")
    if not ok then
        print("Error: Carga package not found")
        return false
    end
    
    local migration_ok, Migration = pcall(require, "carga.src.migration")
    if not migration_ok then
        print("Error: Carga Migration module not found")
        return false
    end
    
    -- Configure migration system
    Migration.configure({
        migrations_path = "db/migrate"
    })
    
    -- Run migrations using Carga's migration system
    local success, err = pcall(function()
        Migration.migrate()
    end)
    
    if not success then
        print("Error running migrations: " .. tostring(err))
        return false
    end
    
    return true
end

function DbCommand.rollback_migrations(step)
    step = step or 1
    
    -- Initialize database
    local ok, carga = pcall(require, "carga")
    if not ok then
        print("Error: Carga package not found")
        return false
    end
    
    local migration_ok, Migration = pcall(require, "carga.src.migration")
    if not migration_ok then
        print("Error: Carga Migration module not found")
        return false
    end
    
    -- Configure migration system
    Migration.configure({
        migrations_path = "db/migrate"
    })
    
    -- Connect to database
    carga.Database.connect(DbCommand.get_database_path())
    
    -- Rollback migrations using Carga's migration system
    local success, err = pcall(function()
        for i = 1, step do
            Migration.rollback()
        end
    end)
    
    if not success then
        print("Error rolling back migrations: " .. tostring(err))
        return false
    end
    
    return true
end

function DbCommand.seed_database()
    print("Seeding database...")
    
    -- Check if seeds file exists
    if not FileUtils.exists("db/seeds.lua") then
        print("No seeds file found (db/seeds.lua)")
        return true
    end
    
    -- Initialize database
    if not DbCommand.create_database() then
        return false
    end
    
    -- Load and run seeds
    local ok, seeds = pcall(require, "db.seeds")
    if ok then
        if type(seeds) == "function" then
            local success, err = pcall(seeds)
            if success then
                print("Database seeded successfully")
            else
                print("Error running seeds: " .. tostring(err))
                return false
            end
        else
            print("Seeds file should return a function")
            return false
        end
    else
        print("Error loading seeds file: " .. tostring(seeds))
        return false
    end
    
    return true
end

function DbCommand.reset_database()
    print("Resetting database...")
    
    -- Remove database file
    local db_path = DbCommand.get_database_path()
    if FileUtils.exists(db_path) then
        os.remove(db_path)
        print("Dropped database: " .. db_path)
    end
    
    -- Recreate and migrate
    if not DbCommand.create_database() then
        return false
    end
    
    if not DbCommand.run_migrations() then
        return false
    end
    
    if not DbCommand.seed_database() then
        return false
    end
    
    print("Database reset completed")
    return true
end

function DbCommand.show_status()
    -- Initialize database
    local ok, carga = pcall(require, "carga")
    if not ok then
        print("Error: Carga package not found")
        return false
    end
    
    local migration_ok, Migration = pcall(require, "carga.src.migration")
    if not migration_ok then
        print("Error: Carga Migration module not found")
        return false
    end
    
    -- Configure migration system
    Migration.configure({
        migrations_path = "db/migrate"
    })
    
    -- Connect to database
    carga.Database.connect(DbCommand.get_database_path())
    
    -- Show status using Carga's migration system
    local success, err = pcall(function()
        Migration.status()
    end)
    
    if not success then
        print("Error showing migration status: " .. tostring(err))
        return false
    end
    
    return true
end

function DbCommand.run(parsed_args)
    if parsed_args.options.help then
        DbCommand.show_help()
        return true
    end
    
    local action = parsed_args.subcommand
    if not action then
        print("Error: Database action is required")
        DbCommand.show_help()
        return false
    end
    
    if action == "create" then
        return DbCommand.create_database()
    elseif action == "migrate" then
        return DbCommand.run_migrations()
    elseif action == "rollback" then
        local step = tonumber(parsed_args.options.step) or 1
        return DbCommand.rollback_migrations(step)
    elseif action == "seed" then
        return DbCommand.seed_database()
    elseif action == "reset" then
        return DbCommand.reset_database()
    elseif action == "status" then
        return DbCommand.show_status()
    else
        print("Error: Unknown database action '" .. action .. "'")
        DbCommand.show_help()
        return false
    end
end

return DbCommand