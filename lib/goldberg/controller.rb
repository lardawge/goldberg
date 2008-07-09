module Goldberg
  module Controller
    def self.included(base)
      base.class_eval do
        base.append_view_path(["#{RAILS_ROOT}/vendor/plugins/goldberg/app/views"])
        base.layout "application"
      end
    end
  end
end
