# GoldbergFilters
require 'goldberg/credentials'
require 'goldberg/menu'
require 'goldberg/user'

module GoldbergFilters

  def goldberg_security_up
    if Goldberg.settings
      Goldberg::AuthController.set_user(session)
      
      if Goldberg.credentials.role_id != Goldberg.settings.public_role_id
        logger.info "(Logged-in user)"
        if Goldberg.settings.session_timeout > 0 and session[:last_time]
          if (Time.now - session[:last_time]) > Goldberg.settings.session_timeout
            logger.info "Session: time expired"
            Goldberg::AuthController.logout(session)
            redirect_to Goldberg.settings.session_expired_page.url
            return false
          else
            logger.info "Session: time NOT expired"
          end
        end
      end
      
      # If this is a page request check that it exists, and if not
      # redirect to the "unknown" page
      is_page_request = false
      if params[:controller] == 'goldberg/content_pages' and
          params[:action] == 'view'
        is_page_request = true
        if not Goldberg.credentials.pages.has_key?(params[:page_name].to_s)
          logger.warn "(Unknown page? #{params[:page_name].to_s})"
          redirect_to Goldberg.settings.not_found_page.url
          return false
        end
      end
      
      # PERMISSIONS
      # Check whether the user is authorised for this page or action.
      if is_page_request
        authorised = Goldberg.credentials.page_authorised?(params[:page_name].to_s)
      else
        authorised = Goldberg.credentials.action_authorised?(params[:controller],
                                                              params[:action])
      end
      if not authorised
        redirect_to Goldberg.settings.permission_denied_page.url
        return false
      end
    end  # if Goldberg.settings
    
    session[:last_time] = Time.now
    
    return true
  end


  def goldberg_security_down
    Goldberg.clear!
  end
  
end


ActionController::Base.class_eval do
  include GoldbergFilters
  prepend_before_filter :goldberg_security_up
  append_after_filter :goldberg_security_down
end
