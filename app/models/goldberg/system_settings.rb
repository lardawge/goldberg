module Goldberg
  class SystemSettings < ActiveRecord::Base
    set_table_name 'system_settings'
    include Goldberg::Model
    
    attr_accessor :public_role, :default_markup_style
    attr_accessor :site_default_page, :not_found_page, :permission_denied_page,
    :session_expired_page

    # Make sure that all the standard pages have been set.
    validates_presence_of :public_role_id, :site_default_page_id, :not_found_page_id,
    :permission_denied_page_id, :session_expired_page_id

    # If self-reg is enabled, ensure there is a self-reg role set.
    validates_each :self_reg_enabled do |record, attr, value|
      result = true
      if value and not (record.self_reg_role_id and record.self_reg_role_id > 0)
        record.errors.add attr, <<-END
If self-registration is enabled, you must specify the default Role to
assign to self-registered users.
END
        result = false
      end

      if value and not (record.self_reg_confirmation_error_page_id and
                        record.self_reg_confirmation_error_page_id > 0)
        record.errors.add attr, <<-END
If self-registration is enabled, you must specify an error page to be
displayed to any users who try to access the site, but who are not yet
confirmed.
END
        result = false
      end
      result
    end
    
    def public_role
      @public_role ||= Role.find(self.public_role_id)
    end
    
    def site_default_page
      @site_default_page ||= ContentPage.find(self.site_default_page_id)
    end
    
    def not_found_page
      @not_found_page ||= ContentPage.find(self.not_found_page_id)
    end
    
    def permission_denied_page
      @permission_denied_page ||= ContentPage.find(self.permission_denied_page_id)
    end
    
    def session_expired_page
      @session_expired_page ||= ContentPage.find(self.session_expired_page_id)
    end

    def self_reg_confirmation_error_page
      @self_reg_confirmation_error_page ||=
        ContentPage.find(self.self_reg_confirmation_error_page_id)
    end
    
    # Returns an array of system page settings for a given page,
    # or nil if the page is not a system page.
    def system_pages(pageid)
      pages = Array.new
      
      if self.site_default_page_id == pageid
        pages << "Site default page"
      end
      if self.not_found_page_id == pageid
        pages << "Not found page"
      end
      if self.permission_denied_page_id == pageid
        pages << "Permission denied page"
      end
      if self.session_expired_page_id == pageid
        pages << "Session expired page"
      end

      if self.self_reg_confirmation_error_page_id == pageid
        pages << "Self-registration confirmation error page"
      end
      
      if pages.length > 0
        return pages
      else
        return nil
      end
    end

    def get_start_path
      if self.start_path and self.start_path.length > 0
        self.start_path
      else
        "/"
      end
    end
    
    def self_reg_role
      @self_reg_role ||= self.self_reg_role_id ? Role.find(self.self_reg_role_id) :
        Role.new(:id => nil, :name => '(none)')
    end

    def self_reg_confirmation_error_page
      @self_reg_confirmation_error_page ||= (self.self_reg_confirmation_error_page_id ?
                                             ContentPage.find(self.self_reg_confirmation_error_page_id) :
                                             ContentPage.new(:id => nil, :name => '(none)')
                                             )
    end

  end
end
