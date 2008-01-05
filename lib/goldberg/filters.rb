require 'goldberg/system_settings'
require 'goldberg/credentials'
require 'goldberg/menu'
require 'goldberg/user'
require 'goldberg/content_page'
require 'goldberg/role'

module Goldberg
  module Filters

    ERROR_SELF_REG_CONFIRMATION_REQUIRED =
      [1, "Your registration has not yet been confirmed."]
    ERROR_SESSION_EXPIRED =
      [2, "Your session has expired.  Please log in again."]
    ERROR_NOT_FOUND =
      [3, "The page or resource you requested was not found."]
    ERROR_PERMISSION_DENIED =
      [4, "You do not have permission to access that page or resource."]
    
    def goldberg_security_up
      if Goldberg.settings
        session[:goldberg] ||= Hash.new
        session[:goldberg][:path] = request.path

        logger.debug "Setting user..."
        set_user or return false
        
        # Perform some preliminary checks for logged-in users.
        if Goldberg.user
          # Check that the user is not pending registration confirmation.
          logger.debug "Check user not pending registration confirmation..."
          check_not_pending or return false
          # If the user's session has expired, kick out the user.
          logger.debug "Check session not expired..."
          check_not_expired or return false
        end
        
        # The default is false.  check_page_exists() will set this to true if the current request is for a ContentPage.
        @is_page_request = false

        # If this is a page request check that it exists, and if not
        # redirect to the "unknown" page.
        logger.debug "Checking that page exists..."
        check_page_exists or return false
        

        # The default is false. check_permissions() will set this to true if the user is authorised for the current action.
        @authorised = false
        
        # Check whether the user is authorised for this page or action.
        logger.debug "Checking permissions..."
        check_permissions or return false
        
      end  # if Goldberg.settings
      
      session[:last_time] = Time.now
      
      return true
    end


    protected

    def set_user
      Goldberg.clear!
      Goldberg::AuthController.set_user(session)
      return true
    end

    def check_not_pending
      if Goldberg.settings.self_reg_enabled and
          Goldberg.user.self_reg_confirmation_required 
        logger.info "User not confirmed"
        Goldberg::AuthController.logout(session)
        respond_to do |format|
          format.html do
            redirect_to Goldberg.settings.self_reg_confirmation_error_page.url
          end
          format.js do
            render :status => 400, :text =>
              Goldberg.settings.self_reg_confirmation_error_page.content_html
          end
          format.xml do
            render :status => 400, :xml =>
              error_xml(*ERROR_SELF_REG_CONFIRMATION_REQUIRED)
          end
        end
        return false
      end

      return true
    end
    
    def check_not_expired
      if Goldberg.settings.session_timeout > 0 and session[:last_time]
        if (Time.now - session[:last_time]) > Goldberg.settings.session_timeout
          logger.info "Session: time expired"
          Goldberg::AuthController.logout(session)
          respond_to do |format|
            format.html do
              redirect_to Goldberg.settings.session_expired_page.url
            end
            format.js do
              render :status => 400, :text =>
                Goldberg.settings.session_expired_page.content_html
            end
            format.xml do
              render :status => 400, :xml =>
                error_xml(*ERROR_SESSION_EXPIRED)
            end
          end
          return false
        else
          logger.info "Session: time NOT expired"
        end
      end
      
      return true
    end

    def check_page_exists
      if params[:controller] == 'goldberg/content_pages' and
          params[:action] == 'view'
        @is_page_request = true
        if not Goldberg.credentials.pages.has_key?(params[:page_name].join '/')
          logger.warn "(Unknown page? #{params[:page_name].join '/'})"
          respond_to do |format|
            format.html do
              redirect_to Goldberg.settings.not_found_page.url
            end
            format.js do
              render :status => 404, :text => Goldberg.settings.not_found_page.content_html
            end
            format.xml  do
              render :status => 404, :xml => error_xml(*ERROR_NOT_FOUND)
            end
          end
          return false
        end
      end

      return true
    end

    def check_permissions
      if @is_page_request
        @authorised =
          Goldberg.credentials.page_authorised?(params[:page_name].join '/')
      else
        @authorised = Goldberg.credentials.action_authorised?(params[:controller],
                                                              params[:action])
      end
      if not @authorised
        respond_to do |format|
          format.html do
            if Goldberg.user
              redirect_to Goldberg.settings.permission_denied_page.url
            else
              session[:pending_request] = url_for(params)
              redirect_to :controller => 'goldberg/auth', :action => 'login'
            end
          end
          format.js do
            render :status => 400, :text =>
              Goldberg.settings.permission_denied_page.content_html
          end
          format.xml  do
            render :status => 400, :xml => error_xml(*ERROR_PERMISSION_DENIED)
          end
        end
        return false
      end
      
      return true
    end
    
    def error_xml(code, message)
      target = ''
      xml = Builder::XmlMarkup.new(:target => target)
      xml.instruct!
      xml.error do
        xml.code(code)
        xml.message(message)
        Goldberg.user ? xml.user_id(Goldberg.user.id) : xml.user_id
        xml.params(params.inspect)
      end
      return target
    end

  end  
end


ActionController::Base.class_eval do
  include Goldberg::Filters
  prepend_before_filter :goldberg_security_up
end
