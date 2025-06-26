-- Migration: {{migration_name}}
-- Created: {{timestamp}}

local migration = {}

function migration.up(db)
    db.execute([[
        CREATE TABLE {{table_name}} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
{{table_fields}}
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
{{indexes}}
end

function migration.down(db)
    db.execute("DROP TABLE IF EXISTS {{table_name}}")
end

return migration