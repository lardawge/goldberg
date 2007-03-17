class SelfRegistration < ActiveRecord::Migration
  include GoldbergMigration
  
  def self.up
    # Add fields to SystemSettings to support self registration
    add_column "#{prefix}system_settings", "site_url_prefix", :string
    add_column "#{prefix}system_settings", "self_reg_enabled", :boolean
    add_column "#{prefix}system_settings", "self_reg_role_id", :integer
    add_column "#{prefix}system_settings", "self_reg_confirmation_required", :boolean
    add_column "#{prefix}system_settings", "self_reg_confirmation_error_page_id", :integer
    add_column "#{prefix}system_settings", "self_reg_send_confirmation_email", :boolean

    # User
    add_column "#{prefix}users", "self_reg_confirmation_required", :boolean
    add_column "#{prefix}users", "confirmation_key", :string
    add_column "#{prefix}users", "password_changed_at", :timestamp
    add_column "#{prefix}users", "password_expired", :boolean
  end

  def self.down
    remove_column "#{prefix}users", "password_expired"
    remove_column "#{prefix}users", "password_changed_at"
    remove_column "#{prefix}users", "confirmation_key"
    remove_column "#{prefix}users", "self_reg_confirmation_required"

    remove_column "#{prefix}system_settings", "self_reg_send_confirmation_email"
    remove_column "#{prefix}system_settings", "self_reg_confirmation_required"
    remove_column "#{prefix}system_settings", "self_reg_role_id"
    remove_column "#{prefix}system_settings", "self_reg_enabled"
    remove_column "#{prefix}system_settings", "site_url_prefix"
  end

end

    
