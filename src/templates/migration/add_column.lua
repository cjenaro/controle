-- Migration: {{migration_name}}
-- Created: {{timestamp}}

local migration = {}

function migration.up(db)
{{add_columns}}
end

function migration.down(db)
{{remove_columns}}
end

return migration