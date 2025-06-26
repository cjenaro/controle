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
    
    -- Check if migrations directory exists
    if not FileUtils.is_directory("db/migrate") then
        print("No migrations directory found (db/migrate)")
        return true
    end
    
    -- Initialize database
    if not DbCommand.create_database() then
        return false
    end
    
    -- Find migration files
    local migration_files = FileUtils.find_files("db/migrate", "%.lua$")
    table.sort(migration_files)
    
    if #migration_files == 0 then
        print("No migration files found")
        return true
    end
    
    -- Load Carga
    local ok, carga = pcall(require, "carga")
    if not ok then
        print("Error: Carga package not found")
        return false
    end
    
    -- Create schema_migrations table if it doesn't exist
    carga.Database.execute([[
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version TEXT PRIMARY KEY,
            migrated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    -- Get already migrated versions
    local migrated_result = carga.Database.query("SELECT version FROM schema_migrations")
    local migrated_versions = {}
    for _, row in ipairs(migrated_result.rows) do
        migrated_versions[row.version] = true
    end
    
    -- Run pending migrations
    local migrations_run = 0
    for _, migration_file in ipairs(migration_files) do
        local version = FileUtils.get_basename(migration_file)
        
        if not migrated_versions[version] then
            print("Running migration: " .. version)
            
            -- Load and run migration
            local migration_path = migration_file:gsub("%.lua$", ""):gsub("/", ".")
            local migration_ok, migration = pcall(require, migration_path)
            
            if migration_ok and migration.up then
                local success, err = pcall(migration.up, carga.Database)
                if success then
                    -- Mark as migrated
                    carga.Database.execute(
                        "INSERT INTO schema_migrations (version) VALUES (?)",
                        { version }
                    )
                    migrations_run = migrations_run + 1
                else
                    print("Error running migration " .. version .. ": " .. tostring(err))
                    return false
                end
            else
                print("Error loading migration " .. version)
                return false
            end
        end
    end
    
    if migrations_run == 0 then
        print("No pending migrations")
    else
        print("Ran " .. migrations_run .. " migrations")
    end
    
    return true
end

function DbCommand.rollback_migrations(step)
    step = step or 1
    print("Rolling back " .. step .. " migration(s)...")
    
    -- Initialize database
    local ok, carga = pcall(require, "carga")
    if not ok then
        print("Error: Carga package not found")
        return false
    end
    
    carga.Database.connect(DbCommand.get_database_path())
    
    -- Get migrated versions in reverse order
    local migrated_result = carga.Database.query(
        "SELECT version FROM schema_migrations ORDER BY migrated_at DESC LIMIT ?",
        { step }
    )
    
    if #migrated_result.rows == 0 then
        print("No migrations to rollback")
        return true
    end
    
    -- Rollback migrations
    for _, row in ipairs(migrated_result.rows) do
        local version = row.version
        print("Rolling back migration: " .. version)
        
        -- Find migration file
        local migration_file = "db/migrate/" .. version .. ".lua"
        if not FileUtils.exists(migration_file) then
            print("Warning: Migration file not found: " .. migration_file)
        else
        
        -- Load and run down migration
        local migration_path = migration_file:gsub("%.lua$", ""):gsub("/", ".")
        local migration_ok, migration = pcall(require, migration_path)
        
        if migration_ok and migration.down then
            local success, err = pcall(migration.down, carga.Database)
            if success then
                -- Remove from schema_migrations
                carga.Database.execute(
                    "DELETE FROM schema_migrations WHERE version = ?",
                    { version }
                )
            else
                print("Error rolling back migration " .. version .. ": " .. tostring(err))
                return false
            end
        else
            print("Error: Migration " .. version .. " has no down method")
            return false
        end
        end
    end
    
    print("Rollback completed")
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
    print("Migration Status:")
    print("================")
    
    -- Initialize database
    local ok, carga = pcall(require, "carga")
    if not ok then
        print("Error: Carga package not found")
        return false
    end
    
    carga.Database.connect(DbCommand.get_database_path())
    
    -- Get migrated versions
    local migrated_result = carga.Database.query("SELECT version FROM schema_migrations ORDER BY version")
    local migrated_versions = {}
    for _, row in ipairs(migrated_result.rows) do
        migrated_versions[row.version] = true
    end
    
    -- Find all migration files
    local migration_files = FileUtils.find_files("db/migrate", "%.lua$")
    table.sort(migration_files)
    
    if #migration_files == 0 then
        print("No migration files found")
        return true
    end
    
    for _, migration_file in ipairs(migration_files) do
        local version = FileUtils.get_basename(migration_file)
        local status = migrated_versions[version] and "✓ up" or "✗ down"
        print(string.format("%-40s %s", version, status))
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