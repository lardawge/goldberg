module Goldberg
  class SiteController < ActiveRecord::Base
    include GoldbergModel
    
    validates_presence_of :name, :permission_id
    validates_uniqueness_of :name
    attr_accessor :permission

    def permission
      @permission ||= Permission.find_by_id(self.permission_id)
      return @permission
    end
    
    def actions
      @actions ||= ControllerAction.find(:all,
                                         :conditions =>
                                         "site_controller_id = #{self.id}",
                                         :order => 'name')
    end
    
    def self.classes
      for path in ActionController::Routing.controller_paths do
        self.load_class_files(path)
      end  

      classes = Hash.new
      
      ObjectSpace.each_object(Class) do |klass|
        if klass.respond_to? :controller_path
          if klass.superclass.to_s == ApplicationController.to_s
            classes[klass.controller_path] = klass
          end
        end
      end
      
      return classes
    end
    
    
    def self.load_class_files(path)
      for file in Dir.glob("#{path}/*") do
        if file.match /\.rb$/
          begin
            load file
          rescue
            logger.info "Couldn't load file '#{file}' (already loaded?)"
          end
        elsif File.directory? file
          self.load_class_files(file)
        end
      end
    end
    
  end
end
