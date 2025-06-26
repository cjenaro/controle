-- File system utilities for Controle CLI
local lfs = require("lfs")

--- @class FileUtils
--- @field exists function Check if file or directory exists
--- @field is_directory function Check if path is a directory
--- @field is_file function Check if path is a file
--- @field mkdir_p function Create directory recursively
--- @field read_file function Read entire file content
--- @field write_file function Write content to file
--- @field copy_file function Copy file from source to destination
--- @field list_directory function List directory contents
--- @field get_extension function Get file extension
--- @field get_basename function Get filename without extension
--- @field join_path function Join path components
--- @field getcwd function Get current working directory
--- @field chdir function Change working directory
--- @field remove function Remove file or directory
--- @field find_files function Find files matching pattern recursively
local FileUtils = {}

--- Check if a file or directory exists
--- @param path string File or directory path
--- @return boolean exists True if path exists
function FileUtils.exists(path)
    return lfs.attributes(path) ~= nil
end

--- Check if path is a directory
--- @param path string Path to check
--- @return boolean isDirectory True if path is a directory
function FileUtils.is_directory(path)
    local attr = lfs.attributes(path)
    return attr and attr.mode == "directory"
end

--- Check if path is a file
--- @param path string Path to check
--- @return boolean isFile True if path is a file
function FileUtils.is_file(path)
    local attr = lfs.attributes(path)
    return attr and attr.mode == "file"
end

--- Create directory recursively (like mkdir -p)
--- @param path string Directory path to create
--- @return boolean success True if successful
--- @return string? error Error message if failed
function FileUtils.mkdir_p(path)
    local parts = {}
    for part in path:gmatch("[^/\\]+") do
        table.insert(parts, part)
    end
    
    local current_path = ""
    for i, part in ipairs(parts) do
        if i == 1 and path:match("^/") then
            current_path = "/" .. part
        elseif i == 1 then
            current_path = part
        else
            current_path = current_path .. "/" .. part
        end
        
        if not FileUtils.exists(current_path) then
            local success, err = lfs.mkdir(current_path)
            if not success then
                return false, "Failed to create directory: " .. current_path .. " (" .. tostring(err) .. ")"
            end
        end
    end
    
    return true
end

--- Read entire file content
--- @param path string File path to read
--- @return string? content File content or nil if failed
--- @return string? error Error message if failed
function FileUtils.read_file(path)
    local file, err = io.open(path, "r")
    if not file then
        return nil, "Failed to open file: " .. tostring(err)
    end
    
    local content = file:read("*all")
    file:close()
    
    return content
end

--- Write content to file
--- @param path string File path to write
--- @param content string Content to write
--- @return boolean success True if successful
--- @return string? error Error message if failed
function FileUtils.write_file(path, content)
    -- Create directory if it doesn't exist
    local dir = path:match("(.+)/[^/]+$")
    if dir then
        local success, err = FileUtils.mkdir_p(dir)
        if not success then
            return false, err
        end
    end
    
    local file, err = io.open(path, "w")
    if not file then
        return false, "Failed to create file: " .. tostring(err)
    end
    
    file:write(content)
    file:close()
    
    return true
end

--- Copy file from source to destination
--- @param src string Source file path
--- @param dest string Destination file path
--- @return boolean success True if successful
--- @return string? error Error message if failed
function FileUtils.copy_file(src, dest)
    local content, err = FileUtils.read_file(src)
    if not content then
        return false, err
    end
    
    return FileUtils.write_file(dest, content)
end

--- List directory contents
--- @param path string Directory path
--- @return table<number, string> files List of filenames
function FileUtils.list_directory(path)
    local files = {}
    
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            table.insert(files, file)
        end
    end
    
    return files
end

--- Get file extension
--- @param path string File path
--- @return string? extension File extension without dot
function FileUtils.get_extension(path)
    return path:match("%.([^%.]+)$")
end

--- Get filename without extension
--- @param path string File path
--- @return string basename Filename without extension
function FileUtils.get_basename(path)
    local filename = path:match("([^/\\]+)$")
    return filename:match("(.+)%.[^%.]+$") or filename
end

--- Join path components with proper separators
--- @param ... string Path components to join
--- @return string path Joined path
function FileUtils.join_path(...)
    local parts = {...}
    local path = table.concat(parts, "/")
    
    -- Normalize path separators and remove double slashes
    path = path:gsub("\\", "/"):gsub("//+", "/")
    
    return path
end

-- Get current working directory
function FileUtils.getcwd()
    return lfs.currentdir()
end

-- Change working directory
function FileUtils.chdir(path)
    return lfs.chdir(path)
end

-- Remove file or directory
function FileUtils.remove(path)
    local attr = lfs.attributes(path)
    if not attr then
        return true -- Already doesn't exist
    end
    
    if attr.mode == "directory" then
        -- Remove directory contents first
        for file in lfs.dir(path) do
            if file ~= "." and file ~= ".." then
                local file_path = FileUtils.join_path(path, file)
                local success, err = FileUtils.remove(file_path)
                if not success then
                    return false, err
                end
            end
        end
        
        -- Remove empty directory
        return lfs.rmdir(path)
    else
        -- Remove file
        return os.remove(path)
    end
end

-- Find files matching pattern recursively
function FileUtils.find_files(directory, pattern)
    local files = {}
    
    local function scan_directory(dir)
        for file in lfs.dir(dir) do
            if file ~= "." and file ~= ".." then
                local file_path = FileUtils.join_path(dir, file)
                local attr = lfs.attributes(file_path)
                
                if attr.mode == "directory" then
                    scan_directory(file_path)
                elseif attr.mode == "file" and file:match(pattern) then
                    table.insert(files, file_path)
                end
            end
        end
    end
    
    if FileUtils.is_directory(directory) then
        scan_directory(directory)
    end
    
    return files
end

return FileUtils