module Goldberg
  class Credentials

    attr_accessor :role_id, :updated_at, :role_ids
    attr_accessor :permission_ids
    attr_accessor :controllers, :actions, :pages
    attr_accessor :user
    
    # Create a new credentials object for the given role
    def initialize(role_id)
      @role_id = role_id

      role = Role.find(@role_id)
      @updated_at = role.updated_at

      roles = role.get_parents
      @role_ids = Array.new
      for r in roles do
        @role_ids << r.id
      end

      permissions = Permission.find_for_role(@role_ids)
      @permission_ids = Array.new
      for p in permissions do
        @permission_ids << p.id
      end

      if @permission_ids.length < 1
        @permission_ids << 0
      end

      actions = ControllerAction.actions_allowed(@permission_ids)
      @actions = Hash.new
      for a in actions do
        @actions[a.site_controller.name] ||= Hash.new
        if a.allowed.to_i == 1
          @actions[a.site_controller.name][a.name] = true
        else
          @actions[a.site_controller.name][a.name] = false
        end
      end

      sc = SiteController.table_name
      controllers = SiteController.find_by_sql ["select sc.*, (case when permission_id in (?) then 1 else 0 end) as allowed from #{sc} sc", @permission_ids]
      @controllers = Hash.new
      for c in controllers do
        if c.allowed.to_i == 1
          @controllers[c.name] = true
        else
          @controllers[c.name] = false
        end
      end

      cp = ContentPage.table_name
      pages = ContentPage.find_by_sql ["select id, name, permission_id, (case when permission_id in (?) then 1 else 0 end) as allowed from #{cp}", @permission_ids]
      @pages = Hash.new
      for p in pages do
        if p.allowed.to_i == 1
          @pages[p.name] = true
        else
          @pages[p.name] = false
        end
      end
      
    end

    def controller_authorised?(controller)
      authorised = false  # default
      if @controllers.has_key?(controller)
        if @controllers[controller]
          # logger.info "Controller: authorised"
          authorised = true
        else
          # logger.info "Controller: NOT authorised"
        end
      else
      end
      return authorised
    end
    
    def action_authorised?(controller, action)
      authorised = false  # default
      check_controller = false

      # Check if there's a specific permission for an action
      if @actions.has_key?(controller)
        if @actions[controller].has_key?(action)
          if @actions[controller][action]
            # logger.info "Action: authorised"
            authorised = true
          else
            # logger.info "Action: NOT authorised"
          end
        else
          check_controller = true
        end
      else
        check_controller = true
      end
      
      # Check if there's a general permission for a controller
      if check_controller
        authorised = controller_authorised?(controller)
      end
      
      # logger.info "Authorised? #{authorised.to_s}"
      return authorised
    end

    def page_authorised?(page)
      authorised = false  # default
      
      if page and @pages.has_key?(page.to_s)
        if @pages[page.to_s] == true
          # logger.info "Page: authorised"
          authorised = true
        else
        # logger.info "Page: NOT authorised"
        end
      else
        # logger.warn "(Unknown page? #{page})"
      end
      
      return authorised
    end
    
  end
end
