# Set load paths to include the plugin /app directory
controller_path = "#{File.dirname(__FILE__)}/app/controllers"
model_path      = "#{File.dirname(__FILE__)}/app/models"
helper_path     = "#{File.dirname(__FILE__)}/app/helpers"
$LOAD_PATH << controller_path
$LOAD_PATH << model_path
Dependencies.load_paths += [ controller_path, model_path, helper_path ]
config.controller_paths << controller_path

# Goldberg's libraries
require 'goldberg'
require 'goldberg_filters'
require 'goldberg_helper'
require 'goldberg_routes'
require 'goldberg_controller'
require 'goldberg_model'
require 'goldberg_migration'

# Load Plugin Migrations (if available)
begin
  require 'plugin_migrations'
rescue MissingSourceFile
  nil
end

