-- String utilities for Controle CLI
--- @class StringUtils
--- @field camelize function Convert string to CamelCase
--- @field underscore function Convert CamelCase to snake_case
--- @field tableize function Convert string to table name format
--- @field pluralize function Convert singular to plural
--- @field singularize function Convert plural to singular
--- @field titleize function Convert to title case
--- @field humanize function Convert to human-readable format
--- @field constantize function Convert to CONSTANT_CASE
--- @field trim function Trim whitespace
--- @field split function Split string by delimiter
--- @field join function Join array with delimiter
--- @field starts_with function Check if string starts with prefix
--- @field ends_with function Check if string ends with suffix
--- @field escape_pattern function Escape string for Lua patterns
--- @field random_string function Generate random string
--- @field parse_field_spec function Parse field specification
--- @field parse_fields function Parse multiple field specifications
--- @field field_to_sql function Generate SQL from field definition
local StringUtils = {}

--- Convert string to CamelCase
--- @param str string Input string
--- @return string camelized CamelCase string
function StringUtils.camelize(str)
    return str:gsub("_(%w)", function(letter)
        return letter:upper()
    end):gsub("^%w", string.upper)
end

--- Convert CamelCase to snake_case
--- @param str string Input string
--- @return string underscored snake_case string
function StringUtils.underscore(str)
    return str:gsub("(%u)", function(letter)
        return "_" .. letter:lower()
    end):gsub("^_", "")
end

--- Convert string to table name format (plural, lowercase, underscored)
--- @param str string Input string
--- @return string tableized Table name format
function StringUtils.tableize(str)
    return StringUtils.pluralize(StringUtils.underscore(str))
end

--- Simple pluralization using English rules
--- @param str string Singular string
--- @return string pluralized Plural string
function StringUtils.pluralize(str)
    -- Common irregular plurals
    local irregulars = {
        child = "children",
        person = "people",
        man = "men",
        woman = "women",
        tooth = "teeth",
        foot = "feet",
        mouse = "mice",
        goose = "geese"
    }
    
    if irregulars[str] then
        return irregulars[str]
    end
    
    -- Words that are already plural (common cases)
    local already_plural = {
        "children", "people", "men", "women", "teeth", "feet", "mice", "geese",
        "sheep", "deer", "fish", "species", "series", "data", "information"
    }
    
    for _, plural in ipairs(already_plural) do
        if str == plural then
            return str
        end
    end
    
    -- Check if word might already be plural by checking common plural patterns
    if str:match("ies$") or str:match("ves$") or str:match("ses$") or 
       str:match("shes$") or str:match("ches$") or str:match("xes$") or str:match("zes$") then
        return str -- Already plural
    end
    
    -- Special case: if word ends with 's' but not 'ss', it might already be plural
    -- Common exceptions: words that naturally end in 's' but are singular
    local singular_s_words = {
        "class", "glass", "pass", "mass", "grass", "bass", "loss", "boss", 
        "cross", "dress", "stress", "press", "process", "address", "access",
        "business", "witness", "fitness", "illness", "success", "progress"
    }
    
    local is_singular_s_word = false
    for _, word in ipairs(singular_s_words) do
        if str == word then
            is_singular_s_word = true
            break
        end
    end
    
    -- Apply pluralization rules
    if str:match("s$") and not str:match("ss$") and not is_singular_s_word then
        -- Likely already plural, but check for common patterns
        if str:match("us$") then
            return str:gsub("us$", "i") -- radius -> radii, but this is rare
        else
            return str -- Assume already plural
        end
    elseif str:match("ss$") or str:match("sh$") or str:match("ch$") or str:match("x$") or str:match("z$") or is_singular_s_word then
        return str .. "es"
    elseif str:match("y$") and not str:match("[aeiou]y$") then
        return str:gsub("y$", "ies")
    elseif str:match("f$") then
        return str:gsub("f$", "ves")
    elseif str:match("fe$") then
        return str:gsub("fe$", "ves")
    else
        return str .. "s"
    end
end

--- Simple singularization using English rules
--- @param str string Plural string
--- @return string singularized Singular string
function StringUtils.singularize(str)
    -- Common irregular plurals (reverse mapping)
    local irregulars = {
        children = "child",
        people = "person",
        men = "man",
        women = "woman",
        teeth = "tooth",
        feet = "foot",
        mice = "mouse",
        geese = "goose"
    }
    
    if irregulars[str] then
        return irregulars[str]
    end
    
    -- Handle "ies" endings:
    if str:match("ies$") then
        -- Special cases that should just remove "s" (not replace "ies" with "y")
        local special_cases = {
            "vies$",  -- movies -> movie
            "kies$",  -- cookies -> cookie  
            "gies$",  -- doggies -> doggie
            "nies$",  -- bunnies -> bunnie (though "bunny" is more common)
        }
        
        for _, pattern in ipairs(special_cases) do
            if str:match(pattern) then
                return str:gsub("s$", "")
            end
        end
        
        -- Default case: consonant + y -> ies, so replace "ies" with "y"
        return str:gsub("ies$", "y")
    elseif str:match("ves$") then
        return str:gsub("ves$", "f")
    elseif str:match("ses$") or str:match("shes$") or str:match("ches$") or str:match("xes$") or str:match("zes$") then
        return str:gsub("es$", "")
    elseif str:match("s$") and not str:match("ss$") then
        return str:gsub("s$", "")
    else
        return str
    end
end

-- Convert string to title case
function StringUtils.titleize(str)
    return str:gsub("(%w)([%w]*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

-- Convert string to human-readable format
function StringUtils.humanize(str)
    return StringUtils.titleize(str:gsub("_", " "))
end

-- Convert to constant case (SCREAMING_SNAKE_CASE)
function StringUtils.constantize(str)
    return StringUtils.underscore(str):upper()
end

-- Convert to dash-case (kebab-case)
function StringUtils.dasherize(str)
    return StringUtils.underscore(str):gsub("_", "-")
end

-- Trim whitespace from both ends
function StringUtils.trim(str)
    return str:match("^%s*(.-)%s*$")
end

-- Split string by delimiter
function StringUtils.split(str, delimiter)
    local parts = {}
    local pattern = "([^" .. delimiter .. "]+)"
    
    for part in str:gmatch(pattern) do
        table.insert(parts, part)
    end
    
    return parts
end

-- Join array of strings with delimiter
function StringUtils.join(parts, delimiter)
    return table.concat(parts, delimiter)
end

-- Check if string starts with prefix
function StringUtils.starts_with(str, prefix)
    return str:sub(1, #prefix) == prefix
end

-- Check if string ends with suffix
function StringUtils.ends_with(str, suffix)
    return str:sub(-#suffix) == suffix
end

-- Escape string for use in Lua patterns
function StringUtils.escape_pattern(str)
    return str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

-- Generate a random string
function StringUtils.random_string(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    
    math.randomseed(os.time())
    
    for i = 1, length do
        local index = math.random(1, #chars)
        table.insert(result, chars:sub(index, index))
    end
    
    return table.concat(result)
end

--- Convert field specification to field definition
--- @param spec string Field specification like "name:string"
--- @return table field Field definition with name, type, and options
function StringUtils.parse_field_spec(spec)
    local parts = StringUtils.split(spec, ":")
    local name = parts[1]
    local type_spec = parts[2] or "string"
    
    local field = {
        name = name,
        type = type_spec
    }
    
    -- Handle special types
    if type_spec == "references" then
        field.type = "integer"
        field.foreign_key = true
        field.references = StringUtils.singularize(name:gsub("_id$", ""))
    elseif type_spec == "text" then
        field.type = "text"
    elseif type_spec == "integer" then
        field.type = "integer"
    elseif type_spec == "boolean" then
        field.type = "boolean"
    elseif type_spec == "datetime" then
        field.type = "datetime"
    else
        field.type = "text" -- Default to text
    end
    
    return field
end

--- Parse multiple field specifications
--- @param field_specs table<number, string> Array of field specifications
--- @return table<number, table> fields Array of field definitions
function StringUtils.parse_fields(field_specs)
    local fields = {}
    
    for _, spec in ipairs(field_specs) do
        local field = StringUtils.parse_field_spec(spec)
        table.insert(fields, field)
    end
    
    return fields
end

--- Generate SQL column definition from field
--- @param field table Field definition
--- @return string sql SQL column definition
function StringUtils.field_to_sql(field)
    local sql_type
    
    if field.type == "string" or field.type == "text" then
        sql_type = "TEXT"
    elseif field.type == "integer" then
        sql_type = "INTEGER"
    elseif field.type == "boolean" then
        sql_type = "BOOLEAN"
    elseif field.type == "datetime" then
        sql_type = "DATETIME"
    else
        sql_type = "TEXT"
    end
    
    local definition = field.name .. " " .. sql_type
    
    if field.foreign_key then
        definition = definition .. " REFERENCES " .. StringUtils.pluralize(field.references) .. "(id)"
    end
    
    return definition
end

return StringUtils