-- Migration: {{migration_name}}
-- Created: {{timestamp}}

return {
    up = function(db)
        -- Traditional SQL approach:
        db:execute([[
            CREATE TABLE {{table_name}} (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
{{table_fields}},
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ]])
        
{{indexes}}
        
        -- Model-based approach (alternative):
        -- local {{model_name}} = db:model("{{model_name}}")
        -- db:create_table_from_model({{model_name}})
    end,
    
    down = function(db)
        -- Traditional SQL approach:
        db:execute("DROP TABLE IF EXISTS {{table_name}}")
        
        -- Model-based approach (alternative):
        -- local {{model_name}} = db:model("{{model_name}}")
        -- db:drop_table({{model_name}}.table_name)
    end
}