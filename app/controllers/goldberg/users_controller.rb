require 'digest/sha1'

module Goldberg
  class UsersController < ApplicationController
    include GoldbergController

    # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
    verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }

    before_filter do
      @self_reg = false
      @delegate_reg = false
      true  # proceed...
    end
    before_filter :foreign, :only => [:new, :create, :edit, :update]
    before_filter :enable_self_reg, :only => [:self_show, :self_register, :self_create,
                                              :self_edit, :self_update]
    before_filter :enable_delegate_reg, :only => [:delegate_list, :delegate_show,
                                                  :delegate_register, :delegate_create,
                                                  :delegate_edit, :delegate_update,
                                                  :delegate_destroy]
    def registration_request
      key = Digest::SHA1.hexdigest(self.object_id.to_s + rand.to_s)
      # confirm = UserMailer.create_confirmation_request('Fred Bloggs', 'david@localhost', key)
      UserMailer.deliver_confirmation_request('Fred Bloggs', 'david@localhost', key)

      render :nothing => true
    end
    
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
          # Check that the user's email address is well-formed,
          # e.g. =~ /\A[\w\._%-]+@[\w\.-]+\.[a-zA-Z]{2,4}\z/
        end
      end
      
      if params[:user][:clear_password].length == 0 or
          params[:user][:confirm_password] != params[:user][:clear_password]
        flash[:error] = 'Password invalid!'
        render :action => 'new'
      else
        if @user.save
          flash[:notice] = 'User was successfully created.'
          if @self_reg
            if Goldberg.settings.self_reg_confirmation_required
              if Goldberg.settings.self_reg_send_confirmation_email
                confirm_email = UserMailer.create_confirmation_request(@user.fullname,
                                                                       @user.email,
                                                                       @user.confirmation_key)
                UserMailer.deliver(confirm_email)
              end
              render :action => 'create'
            else
              AuthController.set_user(session, @user.id)
              redirect_to :action => 'self_show'
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
      @user or flash[:error] = 'Sorry, but there is no such confirmation required.'
      render :action => 'confirm_registration'
    end

    def confirm_registration_submit
      @user = User.find(params[:id])
      # Check password and key etc.
      if @user.self_reg_confirmation_required and
          @user.confirmation_key == params[:user][:confirmation_key] and
          @user.check_password(params[:user][:clear_password])
        # Confirmed: remove confirmation flag and confirmation key,
        # save user.
        @user.self_reg_confirmation_required = false
        @user.confirmation_key = nil
        if @user.save
          flash[:notice] = 'Registration confirmed.'
          AuthController.set_user(session, @user.id)
          render :action => 'confirm_registration_submit'
        else
          flash[:error] = 'Could not save confirmation!'
          render :action => 'confirm_registration'
        end
      else
        flash[:error] = 'Self-registration confirmation invalid!'
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
          flash[:error] = 'Password invalid!'
          render :action => 'edit'
        else
          if @user.update_attributes(params[:user])
            flash[:notice] = 'User was successfully updated.'
            redirect_to :action => 'show', :id => @user
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
