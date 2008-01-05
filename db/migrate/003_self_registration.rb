class SelfRegistration < ActiveRecord::Migration
  include Goldberg::Migration
  
  def self.up
    # Add fields to SystemSettings to support self registration
    add_column "#{prefix}system_settings", "start_path", :string
    add_column "#{prefix}system_settings", "site_url_prefix", :string
    add_column "#{prefix}system_settings", "self_reg_enabled", :boolean
    add_column "#{prefix}system_settings", "self_reg_role_id", :integer
    add_column "#{prefix}system_settings",
    "self_reg_confirmation_required", :boolean
    add_column "#{prefix}system_settings",
    "self_reg_confirmation_error_page_id", :integer
    add_column "#{prefix}system_settings",
    "self_reg_send_confirmation_email", :boolean

    # Role
    add_column "#{prefix}roles", "start_path", :string
    
    # User
    add_column "#{prefix}users", "start_path", :string
    add_column "#{prefix}users", "self_reg_confirmation_required", :boolean
    add_column "#{prefix}users", "confirmation_key", :string
    add_column "#{prefix}users", "password_changed_at", :timestamp
    add_column "#{prefix}users", "password_expired", :boolean

    # ContentPage
    add_column "#{prefix}content_pages", "markup_style", :string
  end

  def self.down
    remove_column "#{prefix}content_pages", "markup_style"
    
    remove_column "#{prefix}users", "password_expired"
    remove_column "#{prefix}users", "password_changed_at"
    remove_column "#{prefix}users", "confirmation_key"
    remove_column "#{prefix}users", "self_reg_confirmation_required"
    remove_column "#{prefix}users", "start_path"

    remove_column "#{prefix}roles", "start_path"
    
    remove_column "#{prefix}system_settings", "self_reg_send_confirmation_email"
    remove_column "#{prefix}system_settings",
    "self_reg_confirmation_error_page_id"
    remove_column "#{prefix}system_settings", "self_reg_confirmation_required"
    remove_column "#{prefix}system_settings", "self_reg_role_id"
    remove_column "#{prefix}system_settings", "self_reg_enabled"
    remove_column "#{prefix}system_settings", "site_url_prefix"
    remove_column "#{prefix}system_settings", "start_path"
  end

end

    
