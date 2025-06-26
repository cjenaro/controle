-- {{class_name}} controller
local BaseController = require("comando.base_controller")
local {{model_name}} = require("app.models.{{model_file}}")

--- @class {{class_name}} : BaseController
local {{class_name}} = BaseController:extend()

-- GET /{{route_path}}
function {{class_name}}:index()
    local {{plural_name}} = {{model_name}}:all()
    
    self:render("{{view_path}}/index", {
        {{plural_name}} = {{plural_name}}
    })
end

-- GET /{{route_path}}/:id
function {{class_name}}:show()
    local {{singular_name}} = {{model_name}}:find(self.params.id)
    
    if not {{singular_name}} then
        return self:not_found()
    end
    
    self:render("{{view_path}}/show", {
        {{singular_name}} = {{singular_name}}
    })
end

-- GET /{{route_path}}/new
function {{class_name}}:new()
    local {{singular_name}} = {{model_name}}:new()
    
    self:render("{{view_path}}/new", {
        {{singular_name}} = {{singular_name}}
    })
end

-- POST /{{route_path}}
function {{class_name}}:create()
    local {{singular_name}} = {{model_name}}:new(self.params.{{singular_name}})
    
    if {{singular_name}}:save() then
        self:redirect("/{{route_path}}/" .. {{singular_name}}.id)
    else
        self:render("{{view_path}}/new", {
            {{singular_name}} = {{singular_name}},
            errors = {{singular_name}}.errors
        })
    end
end

-- GET /{{route_path}}/:id/edit
function {{class_name}}:edit()
    local {{singular_name}} = {{model_name}}:find(self.params.id)
    
    if not {{singular_name}} then
        return self:not_found()
    end
    
    self:render("{{view_path}}/edit", {
        {{singular_name}} = {{singular_name}}
    })
end

-- PUT /{{route_path}}/:id
function {{class_name}}:update()
    local {{singular_name}} = {{model_name}}:find(self.params.id)
    
    if not {{singular_name}} then
        return self:not_found()
    end
    
    if {{singular_name}}:update(self.params.{{singular_name}}) then
        self:redirect("/{{route_path}}/" .. {{singular_name}}.id)
    else
        self:render("{{view_path}}/edit", {
            {{singular_name}} = {{singular_name}},
            errors = {{singular_name}}.errors
        })
    end
end

-- DELETE /{{route_path}}/:id
function {{class_name}}:destroy()
    local {{singular_name}} = {{model_name}}:find(self.params.id)
    
    if not {{singular_name}} then
        return self:not_found()
    end
    
    {{singular_name}}:destroy()
    self:redirect("/{{route_path}}")
end

return {{class_name}}