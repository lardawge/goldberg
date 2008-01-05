module Goldberg
  class SystemSettingsController < ApplicationController
    include Goldberg::Controller

    def index
      list
      render :action => 'list'
    end

    # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
    verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }

    def list
      @system_settings = SystemSettings.find(:first)
      redirect_to :action => :show, :id => @system_settings
    end

    def show
      foreign()
      @system_settings = SystemSettings.find(:first)
    end

    def new
      @system_settings = SystemSettings.find(:first)
      if @system_settings != nil
        redirect_to :action => :edit, :id => @system_settings.id
      else
        foreign()
        @system_settings = SystemSettings.new
      end
    end

    def create
      @system_settings = SystemSettings.new(params[:system_settings])
      if @system_settings.save
        flash[:notice] = 'SystemSettings was successfully created.'
        redirect_to :action => 'list'
      else
        render :action => 'new'
      end
    end

    def edit
      foreign()
      @system_settings = SystemSettings.find(params[:id])
    end

    def update
      @system_settings = SystemSettings.find(params[:id])
      if @system_settings.update_attributes(params[:system_settings])
        flash[:notice] = 'SystemSettings was successfully updated.'
        redirect_to :action => 'show', :id => @system_settings
      else
        foreign
        render :action => 'edit'
      end
    end

    def destroy
      SystemSettings.find(params[:id]).destroy
      redirect_to :action => 'list'
    end

    protected

    def foreign
      @roles = Role.find(:all, :order => 'name')
      @self_reg_roles = @roles.clone
      @self_reg_roles.unshift Role.new(:id => nil, :name => '(none)')
      @pages = ContentPage.find(:all, :order => 'name')
    end

  end
end
