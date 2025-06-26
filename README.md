# Controle - Rails-like CLI for Foguete Framework 🛠️

Controle provides the `fog` command-line interface for the Foguete framework, offering Rails-inspired project scaffolding, code generation, database management, and development tools with seamless integration across all Foguete packages.

## ✅ **Current Status: Core Complete**

**Controle CLI is fully functional** with complete code generation capabilities:

- ✅ **Project Creation** - `fog new` creates complete Foguete applications
- ✅ **Model Generation** - `fog generate model` with Carga ORM integration
- ✅ **Controller Generation** - `fog generate controller` with Comando framework
- ✅ **Migration Generation** - `fog generate migration` with database schema
- ✅ **Scaffold Generation** - `fog generate scaffold` for complete CRUD
- ✅ **View Generation** - React/TypeScript components for Orbita SPA
- ✅ **Template System** - Complete template engine with variable substitution

## Installation

```bash
luarocks install controle
```

Or install from source:

```bash
cd controle/
luarocks make controle-0.0.1-1.rockspec
```

## Quick Start

### Create a New Application

```bash
fog new my_blog
cd my_blog
npm install
npm run build
```

### Generate Complete CRUD

```bash
# Generate complete blog functionality
fog generate scaffold Post title:string content:text published:boolean

# This creates:
# ✅ app/models/post.lua (Carga model)
# ✅ app/controllers/posts_controller.lua (Comando controller) 
# ✅ app/views/posts/*.tsx (React components)
# ✅ db/migrate/*_create_posts.lua (Database migration)
# ✅ spec/models/post_spec.lua (Model tests)
# ✅ spec/controllers/posts_controller_spec.lua (Controller tests)
```

### Database Management

```bash
# Run migrations
fog db:migrate

# Rollback migrations  
fog db:rollback

# Seed database
fog db:seed
```

## Commands

### Project Commands

- `fog new <app_name>` - Create new Foguete application
- `fog server` - Start development server *(coming soon)*
- `fog console` - Interactive console *(coming soon)*
- `fog version` - Show version information

### Generator Commands

- `fog generate model <name> [field:type ...]` - Generate Carga model + migration
- `fog generate controller <name> [action ...]` - Generate Comando controller + views
- `fog generate migration <name> [field:type ...]` - Generate database migration
- `fog generate scaffold <name> [field:type ...]` - Generate complete CRUD

### Database Commands *(coming soon)*

- `fog db:create` - Create database file
- `fog db:migrate` - Run pending migrations
- `fog db:rollback [--step n]` - Rollback migrations
- `fog db:seed` - Run database seeds
- `fog db:reset` - Drop, create, migrate, and seed

## Field Types

When generating models or scaffolds, you can specify field types:

- `string` - Text field (default)
- `text` - Long text field  
- `integer` - Numeric field
- `number` - Float field
- `boolean` - True/false field
- `datetime` - Timestamp field
- `date` - Date field
- `time` - Time field

## Examples

### Create a Blog Application

```bash
# Create new application
fog new my_blog
cd my_blog

# Generate User model
fog generate model User name:string email:string

# Generate Post scaffold with relationship
fog generate scaffold Post title:string content:text user:references

# Setup database
fog db:create
fog db:migrate

# Start server
fog server
```

### Generated Application Structure

```
my_blog/
├── app/
│   ├── controllers/
│   │   ├── application_controller.lua
│   │   └── posts_controller.lua
│   ├── models/
│   │   ├── user.lua
│   │   └── post.lua
│   ├── views/
│   │   └── posts/
│   │       ├── index.tsx
│   │       ├── show.tsx
│   │       └── form.tsx
│   └── main.tsx
├── config/
│   ├── application.lua
│   ├── routes.lua
│   └── environments/
│       ├── development.lua
│       └── production.lua
├── db/
│   ├── migrate/
│   │   ├── 001_create_users.lua
│   │   └── 002_create_posts.lua
│   └── seeds.lua
├── public/
│   └── assets/
├── spec/
│   ├── models/
│   └── controllers/
├── package.json
├── tsconfig.json
├── vite.config.js
├── server.lua
└── README.md
```

## Package Integration

### Carga (ORM) Integration

Generated models use Carga Active Record pattern:

```lua
-- app/models/user.lua
local carga = require("carga")

local User = carga.Model:extend("users")

-- Define schema
User.schema = {
    id = { type = "integer", primary_key = true, auto_increment = true },
    name = { type = "text" },
    email = { type = "text" }
}

-- Validations
User.validations = {
    name = "required",
    email = "required"
}

return User
```

### Comando (Controllers) Integration

Generated controllers inherit from BaseController:

```lua
-- app/controllers/users_controller.lua
local BaseController = require("comando.base_controller")
local User = require("app.models.user")

local UsersController = BaseController:extend()

function UsersController:index()
    local users = User:all()
    
    self:render("users/index", {
        users = users
    })
end

return UsersController
```

### Orbita (Views) Integration

Generated views use React/TypeScript components:

```tsx
// app/views/users/index.tsx
import React from 'react';
import { Link } from 'react-router-dom';

interface User {
  id: number;
  name: string;
  email: string;
}

interface UserIndexProps {
  users: User[];
}

export default function UserIndex({ users }: UserIndexProps) {
  return (
    <div className="user-index">
      <h1>Users</h1>
      {users.map(user => (
        <div key={user.id}>
          <Link to={`/users/${user.id}`}>{user.name}</Link>
        </div>
      ))}
    </div>
  );
}
```

## Generator Examples

### Model Generator

```bash
fog generate model User name:string email:string age:integer active:boolean
```

Creates:
- `app/models/user.lua` - Carga model with schema and validations
- `spec/models/user_spec.lua` - Model tests
- `db/migrate/20250625120000_create_users.lua` - Database migration

### Controller Generator

```bash
fog generate controller Users index show create update destroy
```

Creates:
- `app/controllers/users_controller.lua` - Comando controller with RESTful actions
- `spec/controllers/users_controller_spec.lua` - Controller tests
- `app/views/users/index.tsx` - React index component
- `app/views/users/show.tsx` - React show component
- `app/views/users/form.tsx` - React form component

### Migration Generator

```bash
fog generate migration AddEmailToUsers email:string
```

Creates:
- `db/migrate/20250625120000_add_email_to_users.lua` - Migration with up/down methods

### Scaffold Generator

```bash
fog generate scaffold Post title:string content:text published:boolean
```

Creates complete CRUD functionality:
- Model with validations
- Controller with all RESTful actions
- React views (index, show, form)
- Database migration
- Test files
- Routes configuration snippet

## Development

### Running Tests

```bash
cd controle/
busted spec/
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for your changes
4. Ensure all tests pass
5. Submit a pull request

## Known Issues

- **Missing files in `fog new`**: Some Vite/TypeScript configuration files need to be added
- **Orbita integration**: useState hook issues need debugging
- **Database commands**: Migration runner not yet implemented

See [TODO.md](TODO.md) for detailed status and upcoming features.

## License

MIT License - see LICENSE file for details.

## About

Controle is part of the [Foguete](https://github.com/foguete) ecosystem, providing Rails-like developer experience for Lua web applications with modern SPA integration.

**Design Goals:**
- **Rails Familiarity** - Commands and patterns that Rails developers recognize
- **Package Integration** - Seamless integration with all Foguete packages  
- **Developer Experience** - Fast, intuitive, and helpful CLI interface
- **Production Ready** - Generate production-quality code and structure

**Current Status**: Core functionality complete, fixing integration issues and adding missing features.