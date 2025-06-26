-- {{class_name}} model
local carga = require("carga")

--- @class {{class_name}} : Model
--- @field id number Primary key
{{field_declarations}}
local {{class_name}} = carga.Model:extend("{{table_name}}")

-- Define schema
{{class_name}}.schema = {
    id = { type = "integer", primary_key = true, auto_increment = true },
{{schema_fields}}
}

{{validations}}

{{associations}}

-- Custom methods
{{custom_methods}}

return {{class_name}}