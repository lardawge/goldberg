module Goldberg
  module Controller
    def self.included(base)
      base.class_eval do
        base.view_paths =
          ["#{RAILS_ROOT}/vendor/plugins/goldberg/app/views"]
        base.layout "../../../../../app/views/layouts/application"
      end
    end
  end
end
