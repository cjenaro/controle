-- Type definitions for Controle CLI package
-- This file contains all type annotations for better IDE support and documentation

--- @alias ParsedArgs table<string, any> Parsed command line arguments
--- @field command string? Main command name
--- @field subcommand string? Subcommand name
--- @field args table<number, string> Positional arguments
--- @field options table<string, any> Command options and flags

--- @alias FieldDefinition table Field definition for model generation
--- @field name string Field name
--- @field type string Field type (string, integer, boolean, datetime, text)
--- @field foreign_key boolean? True if this is a foreign key
--- @field references string? Referenced model name for foreign keys

--- @alias TemplateContext table<string, any> Variables available in templates
--- @field name string Generator name
--- @field class_name string CamelCase class name
--- @field table_name string Pluralized table name
--- @field singular_name string Singular form of name
--- @field plural_name string Plural form of name
--- @field underscore_name string snake_case name
--- @field constant_name string CONSTANT_CASE name
--- @field human_name string Human readable name
--- @field fields table<number, FieldDefinition>? Field definitions for models

--- @alias GeneratorOptions table<string, any> Options for code generators
--- @field force boolean? Overwrite existing files
--- @field fields table<number, string>? Field specifications for models
--- @field actions table<number, string>? Action names for controllers

--- @alias DatabaseResult table Result from database query
--- @field rows table<number, table<string, any>> Query result rows
--- @field count number Number of rows returned

--- @alias FileAttributes table File system attributes from lfs
--- @field mode string File type ("file", "directory", etc.)
--- @field size number File size in bytes
--- @field modification number Last modification time

--- @class CommandModule
--- @field show_help function Show help for the command
--- @field run function Execute the command

--- @class GeneratorModule
--- @field new function Create new generator instance
--- @field extend function Extend generator class
--- @field generate function Main generation method
--- @field run function Run the generator

--- Command result type
--- @alias CommandResult boolean True if command succeeded, false otherwise

--- Template rendering result
--- @alias TemplateResult string|nil Rendered template content or nil if failed

--- File operation result
--- @alias FileResult boolean|string True if successful, error message if failed

return {}