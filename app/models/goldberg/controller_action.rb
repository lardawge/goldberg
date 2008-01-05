module Goldberg
  class ControllerAction < ActiveRecord::Base
    include Goldberg::Model
    
    belongs_to :site_controller
    belongs_to :permission
    
    validates_presence_of :name, :site_controller_id
    validates_uniqueness_of :name, :scope => 'site_controller_id'
    
    attr_accessor :allowed, :specific_name
  
    def effective_permission
      self.permission || self.site_controller.permission
    end

    def fullname
      if self.site_controller_id and self.site_controller_id > 0
        return "#{self.site_controller.name}: #{self.name}"
      else
        return "#{self.name}"
      end
    end

    def url
      @url ||= "/#{self.site_controller.name}/#{self.name}"
    end

    def menu_items
      if self.id
        MenuItem.find_all_by_controller_action_id(self.id, :order => 'label')
      else
        []
      end
    end

    def before_destroy
      if self.menu_items.length > 0
        self.errors.add(:id, "Cannot delete an Action that is in the menu!")
        return false
      else
        return true
      end
    end
    
    def self.actions_allowed(permission_ids)
      # Hash for faster & easier lookups
      if permission_ids
        perms = {}
        for id in permission_ids do
          perms[id] = true
        end
      end

      actions = ControllerAction.find(:all)
      for action in actions do
        if action.permission_id
          if perms.has_key?(action.permission_id)
            action.allowed = 1
          else
            action.allowed = 0
          end
        else  # Controller's permission
          if perms.has_key?(action.site_controller.permission_id)
            action.allowed = 1
          else
            action.allowed = 0
          end
        end
      end

      return actions
    end

    def self.find_for_permission(p_ids)
      if p_ids and p_ids.length > 0
        return find(:all, 
                    :conditions => ['permission_id in (?)', p_ids],
                    :order => 'name')
      else
        return Array.new
      end
    end

  end
end
