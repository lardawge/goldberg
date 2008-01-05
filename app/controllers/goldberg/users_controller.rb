require 'digest/sha1'

module Goldberg
  class UsersController < ApplicationController
    include Goldberg::Controller

    # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
    verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }

    before_filter do
      @self_reg = false
      @delegate_reg = false
      true  # proceed...
    end
    before_filter :foreign,
    :only => [:new,    :delegate_register, :create, :delegate_create,
              :edit,   :delegate_edit,     :update, :delegate_update]
    before_filter :enable_self_reg,
    :only => [:self_show, :self_register, :self_create, :self_edit,
              :self_update, :confirm_registration, :confirm_registration_submit]
    before_filter :enable_delegate_reg,
    :only => [:delegate_list, :delegate_show, :delegate_register,
              :delegate_create, :delegate_edit, :delegate_update,
              :delegate_destroy]
    
    def list
      if @delegate_reg
        conditions = ['role_id in (?)', Goldberg.credentials.role_ids]
      else
        conditions = nil
      end
      @users = User.find(:all, :conditions => conditions, :order => 'name')
      render :action => 'list'
    end
    alias_method :delegate_list, :list
    
    def show
      if @self_reg
        @user = Goldberg.user
      else
        @user = User.find(params[:id])
      end
      if @user
        if @user.role_id
          @role = Role.find(@user.role_id)
        else
          @role = Role.new(:id => nil, :name => '(none)')
        end
        render :action => 'show'
      else
        render :nothing => true
      end
    end
    alias_method :self_show, :show
    alias_method :delegate_show, :show
    
    def new
      @user = User.new
      render :action => 'new'
    end
    alias_method :self_register, :new
    alias_method :delegate_register, :new
    
    def create
      @user = User.new(params[:user])
      if @self_reg
        @user.role_id = Goldberg.settings.self_reg_role_id
        @user.self_reg_confirmation_required =
          Goldberg.settings.self_reg_confirmation_required
        if Goldberg.settings.self_reg_send_confirmation_email
          if not @user.email_valid?
            flash.now[:error] = 'A valid email address is required!'
            render :action => 'new'
            return
          end
        end
      end
      
      if params[:user][:clear_password].length == 0 or
          params[:user][:confirm_password] != params[:user][:clear_password]
        flash.now[:error] = 'Password invalid!'
        render :action => 'new'
      else
        if @user.save
          flash.now[:notice] = 'User was successfully created.'
          if @self_reg
            if Goldberg.settings.self_reg_confirmation_required
              if Goldberg.settings.self_reg_send_confirmation_email
                confirm_email = UserMailer.create_confirmation_request(@user)
                UserMailer.deliver(confirm_email)
              end
              render :action => 'create'
            else
              AuthController.set_user(session, @user.id)
              redirect_to @user.get_start_path
            end
          else
            redirect_to :action => 'list'
          end
        else
          render :action => 'new'
        end
      end
    end
    alias_method :self_create, :create
    alias_method :delegate_create, :create

    # Invoked when a user clicks on a link in a self-registration
    # email.  Displays a form where the user can enter their username
    # and password.
    def confirm_registration
      @user = User.find_by_confirmation_key(params[:id])
      @user or flash.now[:error] = 'Sorry, but there is no such confirmation required.'
      render :action => 'confirm_registration'
    end

    def confirm_registration_submit
      @user = User.find(params[:id])
      # Check password and key etc.
      if @user and @user.self_reg_confirmation_required and
          @user.confirmation_key == params[:user][:confirmation_key] and
          @user.check_password(params[:user][:clear_password])
        # Confirmed: remove confirmation flag and confirmation key,
        # save user.
        @user.self_reg_confirmation_required = false
        @user.confirmation_key = nil
        if @user.save
          flash.now[:notice] = 'Registration confirmed.'
          AuthController.set_user(session, @user.id)
          render :action => 'confirm_registration_submit'
        else
          flash.now[:error] = 'Could not save confirmation!'
          render :action => 'confirm_registration'
        end
      else
        flash.now[:error] = 'Self-registration confirmation invalid!'
        render :action => 'confirm_registration'
      end
    end
    
    def edit
      if @self_reg
        @user = Goldberg.user
      else
        @user = User.find(params[:id])
      end
      if @user
        if @user.role_id
          @role = Role.find(@user.role_id)
        end
        render :action => 'edit'
      else
        render :nothing => true
      end
    end
    alias_method :self_edit, :edit
    alias_method :delegate_edit, :edit
    
    def update
      if @self_reg
        @user = Goldberg.user
      else
        @user = User.find(params[:id])
      end
      if @user
        if params[:user]['clear_password'] == ''
          params[:user].delete('clear_password')
        end

        # Not allowed to change your own role.
        if @self_reg
          params[:user][:role_id] = @user.role_id
        end
        
        if params[:user][:clear_password] and
            params[:user][:clear_password].length > 0 and
            params[:user][:confirm_password] != params[:user][:clear_password]
          flash.now[:error] = 'Password invalid!'
          render :action => 'edit'
        else
          if @user.update_attributes(params[:user])
            flash.now[:notice] = 'User was successfully updated.'
            redirect_to :action => (@self_reg ? 'self_show' : 'show'),
            :id => @user
          else
            render :action => 'edit'
          end
        end
      end  # if @user
    end  # def update
    alias_method :self_update, :update
    alias_method :delegate_update, :update
    
    def destroy
      User.find(params[:id]).destroy
      redirect_to :action => 'list'
    end
    alias_method :delegate_destroy, :destroy

    def forgot_password
      render :action => 'forgot_password'
    end

    def forgot_password_submit
      @user = User.find_by_name_and_email(params[:user][:name],
                                          params[:user][:email])
      if @user
        if (not @user.self_reg_confirmation_required)
          @user.set_confirmation_key
          if @user.save
            # Send email with confirmation key
            reset_email = UserMailer.create_reset_password_request(@user)
            UserMailer.deliver(reset_email)
            render :action => 'forgot_password_submit'
          else
            render :action => 'forgot_password'
          end
        else
          flash.now[:error] = "You can't reset your password because your account is not yet confirmed."
          render :action => 'forgot_password'
        end
      else
        flash.now[:error] = "No such user/email."
        render :action => 'forgot_password'
      end
    end
    
    def reset_password
      # Find user by confirmation key.
      # Render form with confirmation key, username and email.
      @user = User.find_by_confirmation_key(params[:id])
      if @user
        render :action => 'reset_password'
      else
        flash.now[:error] = 'Sorry, but we received no such password reset request.'
        render :action => 'forgot_password'
      end
    end

    def reset_password_submit
      @user = User.find_by_confirmation_key(params[:id])
      if @user
        if (not @user.self_reg_confirmation_required)
          # set @user.clear_password
          password = @user.class.random_password
          @user.clear_password = password
          @user.password_expired = true
          if @user.save
            # Send email with confirmation key
            password_email = UserMailer.create_reset_password(@user, password)
            UserMailer.deliver(password_email)
            render :action => 'reset_password_submit'
          else
            render :action => 'reset_password'
          end
        else
          flash.now[:error] = "You can't reset your password because your account is not yet confirmed."
          render :action => 'forgot_password'
        end
      else
        flash.now[:error] = "No such password reset request for user."
        render :action => 'forgot_password'
      end
    end
    
    protected

    def foreign
      if @delegate_reg
        conditions = ['id in (?)', Goldberg.credentials.role_ids]
      else
        conditions = nil
      end
      @roles = Role.find(:all, :conditions => conditions, :order => 'name')
    end

    def enable_self_reg
      @self_reg = (Goldberg.settings.self_reg_enabled || false)
      # (This will also halt the filter chain if self-reg is NOT enabled.)
    end

    def enable_delegate_reg
      @delegate_reg = true
    end
    
    def enable_password_change
      @password_change = true
      true  # proceed...
    end

  end
end
