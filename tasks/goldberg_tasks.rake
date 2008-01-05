namespace :goldberg do

  desc "Dump standard Goldberg tables to files in db/"
  task :dump_bootstrap => :environment do
    Goldberg::Migration.dump_bootstrap
  end

  desc "Migrate Goldberg"
  task :migrate => :environment do
    Goldberg::Migrator.plugin_name = 'goldberg'
    Goldberg::Migrator.migrate(ENV['VERSION'])
  end
  
  desc "Load standard Goldberg tables from files in db/"
  task :load_bootstrap => :migrate do
    Goldberg::Migration.load_bootstrap
  end

  desc "Install Goldberg"
  task :install => :load_bootstrap do
    index = "#{RAILS_ROOT}/public/index.html"
    FileTest.exists?(index) and File.delete(index)
  end

  desc "Upgrade Goldberg"
  task :upgrade => :migrate do
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
