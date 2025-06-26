-- {{class_name}} model spec
local {{class_name}} = require("app.models.{{file_name}}")

describe("{{class_name}}", function()
    before_each(function()
        -- Set up test database
        carga.Database.execute("DELETE FROM {{table_name}}")
    end)
    
    describe("validations", function()
        it("should be valid with valid attributes", function()
            local {{instance_name}} = {{class_name}}:new({
{{valid_attributes}}
            })
            
            assert.is_true({{instance_name}}:is_valid())
        end)
        
{{validation_tests}}
    end)
    
    describe("associations", function()
{{association_tests}}
    end)
    
    describe("custom methods", function()
{{custom_method_tests}}
    end)
end)