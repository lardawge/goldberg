class MenuRestItemsUsersCachedContentPages < ActiveRecord::Migration
  include Goldberg::Migration

  def self.up
    # Add URL to use for Actions, to better support REST
    add_column "#{prefix}controller_actions", "url_to_use", :string

    # Enhancements for Users
    add_column "#{prefix}users", "password_salt", :string
    add_column "#{prefix}users", "fullname", :string
    add_column "#{prefix}users", "email", :string

    # Add caching for ContentPages
    add_column "#{prefix}content_pages", "content_cache", :text
  end

  def self.down
    remove_column "#{prefix}content_pages", "content_cache"

    remove_column "#{prefix}users", "email"
    remove_column "#{prefix}users", "fullname"
    remove_column "#{prefix}users", "password_salt"

    remove_column "#{prefix}controller_actions", "url_to_use"
  end
end
