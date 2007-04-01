module Goldberg
  class AuthController < ApplicationController
    include GoldbergController

    def self.set_user(session, user_id = nil)
      session[:goldberg] ||= {}
      find_user_id = user_id || session[:goldberg][:user_id]
      Goldberg.user = (if find_user_id then Goldberg::User.find(find_user_id) else nil end)
      
      if Goldberg.user
        role = Goldberg.user.role
      else
        role = Goldberg::Role.find(Goldberg.settings.public_role_id)
      end
        
      if role
        if not role.cache or not role.cache.has_key?(:credentials)
          Role.rebuild_cache
          role = Goldberg::Role.find(role.id)
        end
        # session[:credentials] = role.cache[:credentials]
        Goldberg.credentials = role.cache[:credentials]
        Goldberg.menu = role.cache[:menu]
        Goldberg.menu.select(session[:goldberg][:menu_item])
        logger.info "Logging in user as role #{role.name}"
      else
        logger.error "Something went seriously wrong with the role"
      end

      if Goldberg.user 
        session[:goldberg][:user_id] = Goldberg.user.id
      end
    end
    
    def login
      if request.get?
        self.class.clear_session(session)
        render :action => 'login'
      else
        user = User.find_by_name(params[:login][:name])
        
        if user and user.check_password(params[:login][:password])
          logger.info "User #{params[:login][:name]} successfully logged in"
          Goldberg.user = user
          self.class.set_user(session, user.id)

          respond_to do |wants|
            wants.html do
              redirect_to user.get_start_path
            end
            wants.xml do
              render :nothing => true, :status => 200
            end
          end
          
        else
          logger.warn "Failed login attempt"
          respond_to do |wants|
            wants.html do
              flash.now[:error] = "Incorrect username/password"
              render :action => 'login'
            end
            wants.xml do
              render :nothing => true, :status => 404
            end
          end
        end
      end
    end  # def login
    
    def logout
      if request.post?
        self.class.logout(session)
      end
      redirect_to Goldberg.settings.public_role.get_start_path
    end

    
    protected

    def self.logout(session)
      session.delete
      self.clear_session(session)
    end

    def self.clear_session(session)
      session[:goldberg] = {}
    end

  end
end
