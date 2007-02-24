module Goldberg
  class AuthController < ApplicationController
    include GoldbergController

    # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
    verify :method => :post, :only => [ :login, :logout ],
    :redirect_to => { :action => :list }

    def login
      if request.get?
        AuthController.clear_session(session)
      else
        user = User.find_by_name(params[:login][:name])
        
        if user and user.check_password(params[:login][:password])
          logger.info "User #{params[:login][:name]} successfully logged in"
          session[:user] = user
          if user.role_id
            role = Role.find(user.role_id)
            if role
              if not role.cache or not role.cache.has_key?(:credentials)
                Role.rebuild_cache
              end
              session[:credentials] = role.cache[:credentials]
              session[:menu] = role.cache[:menu]
              logger.info "Logging in user as role #{session[:credentials].class}"
            else
              logger.error "Something went seriously wrong with the role"
            end
          end
          
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
      AuthController.logout(session)
      redirect_to '/'
    end

    
    protected

    def self.logout(session)
      session.delete
      self.clear_session(session)
    end

    def self.clear_session(session)
      session[:user_id] = nil
      session[:user] = nil
      session[:credentials] = nil
      session[:menu] = nil
      session[:clear] = true
    end

  end
end
