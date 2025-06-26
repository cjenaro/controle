-- fog server command - Start development server
local ServerCommand = {}

function ServerCommand.show_help()
    print([[
Usage: fog server [options]

Start the Foguete development server.

Options:
    -p, --port <port>    Port to run server on (default: 8080)
    -h, --host <host>    Host to bind to (default: 127.0.0.1)
    --help               Show this help message

Examples:
    fog server
    fog server --port 3000
    fog server --host 0.0.0.0 --port 8080
]])
end

function ServerCommand.run(parsed_args)
    if parsed_args.options.help then
        ServerCommand.show_help()
        return true
    end
    
    -- Get port and host from options or environment
    local port = parsed_args.options.port or parsed_args.options.p or os.getenv("PORT") or "8080"
    local host = parsed_args.options.host or parsed_args.options.h or os.getenv("HOST") or "127.0.0.1"
    
    port = tonumber(port)
    if not port then
        print("Error: Invalid port number")
        return false
    end
    
    print("Starting Foguete development server...")
    print("Host: " .. host)
    print("Port: " .. port)
    print("Environment: " .. (os.getenv("FOGUETE_ENV") or "development"))
    
    -- Execute the server.lua file
    local command = "lua server.lua"
    
    -- Set environment variables
    os.execute("export PORT=" .. port .. " && export HOST=" .. host .. " && " .. command)
    
    return true
end

return ServerCommand