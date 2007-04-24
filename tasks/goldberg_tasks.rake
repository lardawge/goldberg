
namespace :goldberg do

  desc "Dump standard Goldberg tables to files in db/"
  task :dump_bootstrap => :environment do
    goldberg_classes.each do |klass|
      dump_for_class klass, "#{File.dirname(__FILE__)}/../db"
    end
  end

  desc "PluginAWeek migrations"
  task :plugin_migrations => :environment do
    begin
      # Try running plugin_migrations from the plugin gem...
      require 'plugin_migrations'
      # If plugin_migrations is loaded too late, Goldberg may have
      # been missed.  If so, add it manually.
      (Rails.plugins.find do |p| p.name == 'goldberg' end) ||
        Rails.plugins << Plugin.new("#{RAILS_ROOT}/vendor/plugins/goldberg")
      # Migrate plugins
      PluginAWeek::PluginMigrations.migrate
    rescue MissingSourceFile
      # ...but if the gem isn't found, plugin_migrations might be
      # installed directly in vendor/plugins.  Try running the rake
      # task.
      Rake::Task['db:migrate:plugins'].invoke
    end
  end
  
  desc "Load standard Goldberg tables from files in db/"
  task :load_bootstrap => :plugin_migrations do
    goldberg_classes.each do |klass|
      load_for_class klass, "#{File.dirname(__FILE__)}/../db"
    end
  end

  desc "Install Goldberg"
  task :install => :load_bootstrap do
    index = "#{RAILS_ROOT}/public/index.html"
    FileTest.exists?(index) and File.delete(index)
  end

  desc "Flush cached data out of sessions and Roles"
  task :flush => :environment do
    puts "Deleting any Rails session files"
    Dir["#{RAILS_ROOT}/tmp/sessions/ruby_sess*"].each do |fname|
      File.delete fname
    end
    
    puts "Deleting any ActiveRecord sessions, and resetting the Role cache"
    conn = ActiveRecord::Base.connection
    begin  # Capture error if sessions table doesn't exist
      conn.execute "delete from sessions"
    rescue
      nil
    end
    # conn.execute "update roles set cache = NULL"
    Goldberg::Role.rebuild_cache
  end

  desc "Upgrade a legacy Goldberg database to the latest version"
  task :upgrade => [:install, :flush] do
    # Prefix all the builtin controllers with 'goldberg/'
    controllers = Goldberg::SiteController.find :all
    controllers.each do |c|
      if c.builtin == 1 and not (c.name =~ /^goldberg/)
        c.name = 'goldberg/' + c.name
        c.save
      end
    end

    # Convert all the numeric markup styles to the new text format.
    pages = Goldberg::ContentPage.find :all
    pages.each do |p|
      case p.markup_style_id
      when 1
        p.markup_style = 'Textile'
      when 2
        p.markup_style = 'Markdown'
      end
      p.save
    end

    # Rebuild role caches
    Goldberg::Role.rebuild_cache

  end

end


def goldberg_classes
  return [ Goldberg::Permission, Goldberg::SiteController, 
           Goldberg::ContentPage, Goldberg::ControllerAction,
           Goldberg::MenuItem, Goldberg::Role,
           Goldberg::RolesPermission, Goldberg::SystemSettings,
           Goldberg::User ]
end

def dump_for_class(klass, dest)
  filename = "#{dest}/#{klass.to_s.sub(/^Goldberg::/, '')}.yml"
  records = klass.find(:all)
  File.open(filename, 'w') do |out|  
    YAML.dump(records, out)
  end
end

def load_for_class(klass, src)
  filename = "#{src}/#{klass.to_s.sub(/^Goldberg::/, '')}.yml"
  File.open(filename) do |src|
    records = YAML::load(src)
    records.each do |src_rec|
      record = klass.new src_rec.attributes
      record.id = src_rec.id
      record.save or 
        puts "#{klass.to_s} record #{record} not saved!"
    end
  end
  # Reset table sequence if applicable (i.e. PostgreSQL)
  if klass.connection.respond_to?(:reset_pk_sequence!)
    klass.connection.reset_pk_sequence!(klass.table_name)
  end
end

