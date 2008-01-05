class ColumnFixes < ActiveRecord::Migration
  include Goldberg::Migration

  def self.up
    # Remove defaults from many compulsory columns, and drop obsolete
    # references to markup_styles
    drop_table "#{prefix}markup_styles"
    
    change_column("#{prefix}permissions", 'name', :string)
    
    change_column("#{prefix}site_controllers", 'name', :string,
                  :default => nil)
    change_column("#{prefix}site_controllers", 'permission_id', :integer,
                  :default => nil)
    
    change_column("#{prefix}content_pages", 'name', :string,
                  :default => nil)
    change_column("#{prefix}content_pages", 'permission_id', :integer,
                  :default => nil)

    change_column("#{prefix}controller_actions", 'site_controller_id', :integer,
                  :default => nil)
    change_column("#{prefix}controller_actions", 'name', :string,
                  :default => nil)

    change_column("#{prefix}menu_items", 'name', :string,
                  :default => nil)
    change_column("#{prefix}menu_items", 'label', :string,
                  :default => nil)

    change_column("#{prefix}roles", 'name', :string,
                  :default => nil)
    
    change_column("#{prefix}roles_permissions", 'role_id', :integer,
                  :default => nil)
    change_column("#{prefix}roles_permissions", 'permission_id', :integer,
                  :default => nil)

    change_column("#{prefix}system_settings", 'site_name', :string,
                  :default => nil)
    change_column("#{prefix}system_settings", 'public_role_id', :integer,
                  :default => nil)
    remove_column("#{prefix}system_settings", 'default_markup_style_id')
    change_column("#{prefix}system_settings", 'site_default_page_id', :integer,
                  :default => nil)
    change_column("#{prefix}system_settings", 'not_found_page_id', :integer,
                  :default => nil)
    change_column("#{prefix}system_settings", 'permission_denied_page_id',
                  :integer, :default => nil)
    change_column("#{prefix}system_settings", 'session_expired_page_id',
                  :integer, :default => nil)

    change_column("#{prefix}users", 'name', :string,
                  :default => nil)
    change_column("#{prefix}users", 'password', :string,
                  :default => nil)
    change_column("#{prefix}users", 'role_id', :integer,
                  :default => nil)
  end

  def self.down
    change_column("#{prefix}users", 'name', :string,
                  :default => '', :null => false)
    change_column("#{prefix}users", 'password', :string,
                  :default => '', :null => false)
    change_column("#{prefix}users", 'role_id', :integer,
                  :default => 0, :null => false)
    
    change_column("#{prefix}system_settings", 'site_name', :string,
                  :default => '', :null => false)
    change_column("#{prefix}system_settings", 'public_role_id', :integer,
                  :default => 0, :null => false)
    add_column("#{prefix}system_settings", 'default_markup_style_id', :integer,
               :default => 0)
    change_column("#{prefix}system_settings", 'site_default_page_id', :integer,
                  :default => 0, :null => false)
    change_column("#{prefix}system_settings", 'not_found_page_id', :integer,
                  :default => 0, :null => false)
    change_column("#{prefix}system_settings", 'permission_denied_page_id',
                  :integer, :default => 0, :null => false)
    change_column("#{prefix}system_settings", 'session_expired_page_id',
                  :integer, :default => 0, :null => false)

    change_column("#{prefix}roles_permissions", 'role_id', :integer,
                  :default => 0, :null => false)
    change_column("#{prefix}roles_permissions", 'permission_id', :integer,
                  :default => 0, :null => false)
    
    change_column("#{prefix}roles", 'name', :string,
                  :default => '', :null => false)
    
    change_column("#{prefix}menu_items", 'name', :string,
                  :default => '', :null => false)
    change_column("#{prefix}menu_items", 'label', :string,
                  :default => '', :null => false)

    change_column("#{prefix}controller_actions", 'site_controller_id', :integer,
                  :default => 0, :null => false)
    change_column("#{prefix}controller_actions", 'name', :string,
                  :default => '', :null => false)

    change_column("#{prefix}content_pages", 'name', :string,
                  :default => '', :null => false)
    change_column("#{prefix}content_pages", 'permission_id', :integer,
                  :default => 0, :null => false)

    change_column("#{prefix}site_controllers", 'name', :string,
                  :default => '', :null => false)
    change_column("#{prefix}site_controllers", 'permission_id', :integer,
                  :default => 0, :null => false)
    
    change_column("#{prefix}permissions", 'name', :string,
                  :default => '', :null => false)
    
    create_table "#{prefix}markup_styles", :force => false do |t|
      t.column "name", :string, :default => "", :null => false
    end
  end
end
