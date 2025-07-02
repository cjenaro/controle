-- {{class_name}} controller
local BaseController = require("comando")
local orbita = require("orbita")
local {{model_name}} = require("app.models.{{model_file}}")

--- @class {{class_name}} : BaseController
local {{class_name}} = {}
{{class_name}}.__index = {{class_name}}
setmetatable({{class_name}}, BaseController)

-- Extend BaseController with Orbita methods
{{class_name}} = orbita.extend_controller({{class_name}})

---@param request motor.HttpRequest
---@return {{class_name}}
function {{class_name}}:new(request)
    local controller = BaseController:new(request)
    setmetatable(controller, self)
    return controller
end

-- GET /{{route_path}}
---@return motor.HttpResponse
function {{class_name}}:index()
    local {{plural_name}} = {{model_name}}:all()
    
    return self:render_orbita("{{view_path}}/index", {
        {{plural_name}} = {{plural_name}}
    })
end

-- GET /{{route_path}}/:id
---@return motor.HttpResponse
function {{class_name}}:show()
    local {{singular_name}} = {{model_name}}:find(self.params.id)
    
    if not {{singular_name}} then
        return self:not_found()
    end
    
    return self:render_orbita("{{view_path}}/show", {
        {{singular_name}} = {{singular_name}}
    })
end

-- GET /{{route_path}}/new
---@return motor.HttpResponse
function {{class_name}}:new_action()
    local {{singular_name}} = {{model_name}}:new()
    
    return self:render_orbita("{{view_path}}/new", {
        {{singular_name}} = {{singular_name}}
    })
end

-- POST /{{route_path}}
---@return motor.HttpResponse
function {{class_name}}:create()
    local data = self:request_data()
    local {{singular_name}} = {{model_name}}:new(data.{{singular_name}})
    
    if {{singular_name}}:save() then
        return self:redirect("/{{route_path}}/" .. {{singular_name}}.id)
    else
        return self:render_orbita("{{view_path}}/new", {
            {{singular_name}} = {{singular_name}},
            errors = {{singular_name}}.errors
        })
    end
end

-- GET /{{route_path}}/:id/edit
---@return motor.HttpResponse
function {{class_name}}:edit()
    local {{singular_name}} = {{model_name}}:find(self.params.id)
    
    if not {{singular_name}} then
        return self:not_found()
    end
    
    return self:render_orbita("{{view_path}}/edit", {
        {{singular_name}} = {{singular_name}}
    })
end

-- PUT /{{route_path}}/:id
---@return motor.HttpResponse
function {{class_name}}:update()
    local {{singular_name}} = {{model_name}}:find(self.params.id)
    
    if not {{singular_name}} then
        return self:not_found()
    end
    
    local data = self:request_data()
    if {{singular_name}}:update(data.{{singular_name}}) then
        return self:redirect("/{{route_path}}/" .. {{singular_name}}.id)
    else
        return self:render_orbita("{{view_path}}/edit", {
            {{singular_name}} = {{singular_name}},
            errors = {{singular_name}}.errors
        })
    end
end

-- DELETE /{{route_path}}/:id
---@return motor.HttpResponse
function {{class_name}}:destroy()
    local {{singular_name}} = {{model_name}}:find(self.params.id)
    
    if not {{singular_name}} then
        return self:not_found()
    end
    
    {{singular_name}}:destroy()
    return self:redirect("/{{route_path}}")
end

return {{class_name}}