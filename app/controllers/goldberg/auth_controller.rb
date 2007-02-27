module Goldberg
  class AuthController < ApplicationController
    include GoldbergController

    # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
    verify :method => :post, :only => [ :login, :logout ],
    :redirect_to => { :action => :list }

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
        AuthController.clear_session(session)
      else
        user = User.find_by_name(params[:login][:name])
        
        if user and user.check_password(params[:login][:password])
          logger.info "User #{params[:login][:name]} successfully logged in"
          Goldberg.user = user
          self.class.set_user(session, user.id)

          respond_to do |wants|
            wants.html do
              redirect_to "/"
            end
            wants.xml do
              render :nothing => true, :status => 200
            end
          end
          
        else
          logger.warn "Failed login attempt"
          respond_to do |wants|
            wants.html do
              redirect_to :action => 'login_failed'
            end
            wants.xml do
              render :nothing => true, :status => 404
            end
          end
        end
      end
    end  # def login
    
    def forgotten
    end

    def login_failed
      flash.now[:error] = "Incorrect Name/Password"
      render :action => 'forgotten'
    end

    def logout
      self.class.logout(session)
      redirect_to '/'
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
