module GoldbergController
  def self.included(base)
    base.class_eval do
      base.template_root = File.join("#{File.dirname(__FILE__)}/../app/views")
      base.layout "../../../../../app/views/layouts/application"
    end
  end
end
