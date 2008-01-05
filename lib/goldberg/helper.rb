module Goldberg
  # Goldberg::Helper will be added as a helper to ActionController::Base,
  # so its methods will be available in the views throughout all
  # controllers (just as if they'd been added to ApplicationHelper).
  module Helper

    # Renders the title of the page: either the ContentPage.name or the
    # current controller and action.
    def goldberg_title
      if params[:controller] == 'goldberg/content_pages' and
          ( params[:action] == 'view' or 
            params[:action] == 'view_default')
        "#{@content_page.title}"
      else
        "#{params[:controller]} | #{params[:action]}" 
      end
    end

    # Renders a top (i.e. one level deep) static menu.
    def goldberg_main_menu
      render :file => "#{RAILS_ROOT}/vendor/plugins/goldberg/app/views/goldberg/menu_items/_menubar.rhtml", :use_full_path => false, :locals => {:level => 0, :depth => 0, :class_attr => nil}
    end

    # Renders a nested side menu, for all levels below the main menu.
    def goldberg_left_menu
      render :file => "#{RAILS_ROOT}/vendor/plugins/goldberg/app/views/goldberg/menu_items/_menubar.rhtml", :use_full_path => false,  
      :locals => {:level => 1, :depth => (Goldberg.settings.menu_depth - 2),
        :class_attr => 'sidemenu'}
    end

    # Renders an entire multilevel suckerfish menu.  Whether this is to
    # be rendered along the top, left hand or right hand side of the
    # page depends on the page's stylesheet.  This code just returns the
    # menu structure.
    def goldberg_suckerfish_menu
      render :file => "#{RAILS_ROOT}/vendor/plugins/goldberg/app/views/goldberg/menu_items/_suckerfish.rhtml", :use_full_path => false, :locals => {:items => Goldberg.menu.get_menu(0)}
    end

    # Renders the breadcrumbs (i.e. representing the user's current
    # position in the menu hierarchy).
    def goldberg_breadcrumbs
      render :file => "#{RAILS_ROOT}/vendor/plugins/goldberg/app/views/goldberg/menu_items/_breadcrumbs.rhtml", :use_full_path => false, :locals => {:crumbs => Goldberg.menu.crumbs}
    end

    # Renders the login prompt.  This changes depending on whether a
    # user is logged in or not.  If a user is logged in, a mini-form is
    # presented with a button to log out.  If not, a link to the
    # auth/login page is presented.
    def goldberg_login
      render :file => "#{RAILS_ROOT}/vendor/plugins/goldberg/app/views/goldberg/auth/_login.rhtml", :use_full_path => false
    end

  end  
end

# You'd think this would work, but it only works on the first request
# after a server restart because helpers get reloaded on each request:

# ApplicationHelper.module_eval do
#  include Goldberg::Helper
# end

# This works:
ActionController::Base.class_eval do
  helper Goldberg::Helper
end
