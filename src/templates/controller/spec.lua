-- {{class_name}} controller spec
local {{class_name}} = require("app.controllers.{{file_name}}")
local {{model_name}} = require("app.models.{{model_file}}")

describe("{{class_name}}", function()
    local controller
    
    before_each(function()
        controller = {{class_name}}:new()
        -- Set up test database
        carga.Database.execute("DELETE FROM {{table_name}}")
    end)
    
    describe("GET #index", function()
        it("should render index template with {{plural_name}}", function()
            -- Create test data
            local {{singular_name}}1 = {{model_name}}:create({{test_attributes}})
            local {{singular_name}}2 = {{model_name}}:create({{test_attributes}})
            
            controller:index()
            
            assert.spy(controller.render).was_called_with(controller, "{{view_path}}/index", {
                {{plural_name}} = match.is_table()
            })
        end)
    end)
    
    describe("GET #show", function()
        it("should render show template with {{singular_name}}", function()
            local {{singular_name}} = {{model_name}}:create({{test_attributes}})
            controller.params = { id = {{singular_name}}.id }
            
            controller:show()
            
            assert.spy(controller.render).was_called_with(controller, "{{view_path}}/show", {
                {{singular_name}} = {{singular_name}}
            })
        end)
        
        it("should return 404 for non-existent {{singular_name}}", function()
            controller.params = { id = 999 }
            
            controller:show()
            
            assert.spy(controller.not_found).was_called()
        end)
    end)
    
    describe("POST #create", function()
        it("should create {{singular_name}} and redirect on success", function()
            controller.params = { {{singular_name}} = {{test_attributes}} }
            
            controller:create()
            
            local created_{{singular_name}} = {{model_name}}:find_by({{test_find_attributes}})
            assert.is_not_nil(created_{{singular_name}})
            assert.spy(controller.redirect).was_called()
        end)
        
        it("should render new template with errors on failure", function()
            controller.params = { {{singular_name}} = {{invalid_attributes}} }
            
            controller:create()
            
            assert.spy(controller.render).was_called_with(controller, "{{view_path}}/new", match.is_table())
        end)
    end)
    
    describe("PUT #update", function()
        it("should update {{singular_name}} and redirect on success", function()
            local {{singular_name}} = {{model_name}}:create({{test_attributes}})
            controller.params = { 
                id = {{singular_name}}.id,
                {{singular_name}} = {{update_attributes}}
            }
            
            controller:update()
            
            {{singular_name}}:reload()
            assert.spy(controller.redirect).was_called()
        end)
    end)
    
    describe("DELETE #destroy", function()
        it("should destroy {{singular_name}} and redirect", function()
            local {{singular_name}} = {{model_name}}:create({{test_attributes}})
            controller.params = { id = {{singular_name}}.id }
            
            controller:destroy()
            
            assert.is_nil({{model_name}}:find({{singular_name}}.id))
            assert.spy(controller.redirect).was_called()
        end)
    end)
end)