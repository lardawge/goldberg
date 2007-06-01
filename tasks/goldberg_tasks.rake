namespace :goldberg do

  desc "Dump standard Goldberg tables to files in db/"
  task :dump_bootstrap => :environment do
    GoldbergMigration.dump_bootstrap
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
    GoldbergMigration.load_bootstrap
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

end
