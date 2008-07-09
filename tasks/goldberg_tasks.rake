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
  
  desc "Apply a site theme"
  task :theme, :theme_name, :needs => :environment do |t, args|
    source_dir = File.join(File.dirname(__FILE__), '..', 'themes')
    theme = args.theme_name || 'goldberg'
    theme_dir = File.join(source_dir, theme)
    if File.directory?(theme_dir)
      manifest = Rails::Generator::Manifest.new do |m|
        # Public assets: images, javascripts and stylesheets, including both the
        # common files and files specific to the specified theme.
        ['images', 'javascripts', 'stylesheets'].each do |asset|
          dest_dir = File.join('public/goldberg', asset)
          m.directory dest_dir
          ['common', theme].each do |src|
            Dir["#{source_dir}/#{src}/public/#{asset}/*"].each do |file_path|
              file = File.basename(file_path)
              m.file "#{src}/public/#{asset}/#{file}", "#{dest_dir}/#{file}"
            end
          end
        end
        # The default site template
        m.file "#{theme}/app/views/layouts/application.html.erb",
        "app/views/layouts/application.html.erb"
      end
      # Run the manifest created above through Rails::Generator
      Rails::Generator::Base.spec = Rails::Generator::Spec.new('', '', nil)
      base = Rails::Generator::Base.new([], :source => source_dir)
      commands = Rails::Generator::Commands::Create.new(base)
      manifest.replay(commands)
    else  # theme directory doesn't exist
      raise ArgumentError.new,
      "No such theme '#{theme}'"
    end
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
