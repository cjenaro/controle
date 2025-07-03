-- Migration: {{migration_name}}
-- Created: {{timestamp}}

return {
    up = function(db)
        -- Model-based approach (recommended):
{{model_add_columns}}
        
        -- Traditional SQL approach (alternative):
{{add_columns_commented}}
    end,
    
    down = function(db)
        -- Model-based approach (recommended):
{{model_remove_columns}}
        
        -- Traditional SQL approach (alternative):
{{remove_columns_commented}}
    end
}