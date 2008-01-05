module Goldberg
  class SiteController < ActiveRecord::Base
    include Goldberg::Model

    belongs_to :permission
    has_many :controller_actions, :order => 'name', :dependent => :destroy
    
    validates_presence_of :name, :permission_id
    validates_uniqueness_of :name

    def self.classes
      for path in ActionController::Routing.controller_paths do
        self.load_class_files(path)
      end  

      classes = Hash.new
      
      ObjectSpace.each_object(Class) do |klass|
        if klass.respond_to? :controller_path
          if (klass.to_s != ApplicationController.to_s and
              klass.ancestors.map{|c|c.to_s}.include?(ApplicationController.to_s))
            classes[klass.controller_path] = klass
          end
        end
      end
      
      return classes
    end
    
    
    def self.load_class_files(path)
      prereqs = []
      files = []
      dirs = []
      for file in Dir.glob("#{path}/*").sort do
        if file.match /_controller\.rb$/
          files << file
        elsif file.match /\.rb$/
          prereqs << file
        elsif File.directory? file
          dirs << file
        end
      end

      (prereqs + files).each do |file|
        begin
          load file
        rescue
          logger.info "Couldn't load file '#{file}' (already loaded?)"
        end
      end

      dirs.each do |dir|
        self.load_class_files(dir)
      end
    end
    
  end
end
