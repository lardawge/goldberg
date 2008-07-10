# Provide separate migrations for plugins.

# Goldberg::Migrator inherits from ActiveRecord::Migrator, overriding
# some methods to allow migration data for plugins to be stored in the
# table "plugin_schema_migrations".  This also requires modifying some
# methods in ActiveRecord::ConnectionAdapters::SchemaStatements.

# This code used to be based on PluginAWeek's plugin_migrations, but
# has been re-written for the new "schema_migrations" system provided
# by Rails 2.1.

module Goldberg
  module SchemaStatements
    def self.included(base) #:nodoc:
      base.class_eval do
        alias_method_chain :dump_schema_information, :plugins
        alias_method_chain :initialize_schema_migrations_table, :plugins
        alias_method_chain :assume_migrated_upto_version, :plugins
      end
    end
    
    # Dumps the plugin schema info table as well as information about the
    # current plugin migrations
    def dump_schema_information_with_plugins
      begin
        sm_table = Goldberg::Migrator.schema_migrations_table_name
        migrated = select_all("SELECT version FROM #{sm_table}")
        migrated.map do |v|
          "INSERT INTO #{sm_table} (plugin_name, version) VALUES ('#{v['plugin_name']}', '#{v['version']}');"
        end.join("\n\n")
      rescue ActiveRecord::StatementInvalid 
        # No Schema Info
        ''
      end
    end

    # Creates the plugin schema info table
    def initialize_schema_migrations_table_with_plugins
      sm_table = Goldberg::Migrator.schema_migrations_table_name
      
      unless tables.detect { |t| t == sm_table }
        create_table(sm_table, :id => false) do |schema_migrations_table|
          schema_migrations_table.column :plugin_name, :string, :null => false
          schema_migrations_table.column :version, :string, :null => false
        end
        add_index sm_table, [:plugin_name, :version], :unique => true,
        :name => 'unique_schema_migrations'
        
        # Backwards-compatibility: if we find schema_info, assume we've
        # migrated up to that point:
        si_table = ActiveRecord::Base.table_name_prefix + 'plugin_schema_info' +
          ActiveRecord::Base.table_name_suffix
        if tables.detect { |t| t == si_table }
          old_version = select_value("SELECT version FROM #{quote_table_name(si_table)} WHERE plugin_name=#{Goldberg::Migrator.plugin}").to_i
          assume_migrated_upto_version(old_version)
          drop_table(si_table)
        end
      end
    end
    
    def assume_migrated_upto_version_with_plugins(version)
      sm_table = Goldberg::Migrator.schema_migrations_table_name
      migration_path = "#{RAILS_ROOT}/vendor/plugins/#{Goldberg::Migrator.plugin_name}/db/migrate"
      
      migrated = select_values("SELECT version FROM #{sm_table} WHERE plugin_name=#{Goldberg::Migrator.plugin}").map(&:to_i)
      versions = Dir["#{migration_path}[0-9]*_*.rb"].map do |filename|
        filename.split('/').last.split('_').first.to_i
      end
      
      execute "INSERT INTO #{sm_table} (plugin_name, version) VALUES (#{Goldberg::Migrator.plugin}, '#{version}')" unless migrated.include?(version.to_i)
      (versions - migrated).select { |v| v < version.to_i }.each do |v|
        execute "INSERT INTO #{sm_table} (plugin_name, version) VALUES (#{Goldberg::Migrator.plugin}, '#{v}')"
      end
    end
    
  end  # module SchemaStatements


  class Migrator < ActiveRecord::Migrator
    class << self
      # Set the plugin name before performing any migrations
      attr_accessor :plugin_name
      
      # Runs the migrations from a plugin, up (or down) to the version given
      def migrate(version = nil)
        ActiveRecord::ConnectionAdapters::SchemaStatements.class_eval do
          include Goldberg::SchemaStatements
        end

        version && (version = version.to_i)
        super("#{RAILS_ROOT}/vendor/plugins/#{plugin_name}/db/migrate", version)
      end
      
      def schema_migrations_table_name
        ActiveRecord::Base.table_name_prefix + 'plugin_schema_migrations' +
          ActiveRecord::Base.table_name_suffix
      end
      
      def current_version
        begin
          version = ActiveRecord::Base.connection.select_values("SELECT version FROM #{schema_migrations_table_name} WHERE plugin_name=#{Goldberg::Migrator.plugin}").map(&:to_i).max
        version || 0
        rescue ActiveRecord::StatementInvalid
          # No migration info table, so never migrated
          0
        end
      end

      # Escape the current plugin name
      def plugin
        ActiveRecord::Base.quote_value(plugin_name)
      end
    end  # class << self
      
    def migrated
      sm_table = self.class.schema_migrations_table_name
      ActiveRecord::Base.connection.select_values("SELECT version FROM #{sm_table} WHERE plugin_name=#{self.class.plugin}").map(&:to_i).sort
    end
    
    private

    def record_version_state_after_migrating(version)
      sm_table = self.class.schema_migrations_table_name
      
      if down?
        ActiveRecord::Base.connection.update("DELETE FROM #{sm_table} WHERE version = '#{version}' AND plugin_name=#{self.class.plugin}")
      else
        ActiveRecord::Base.connection.insert("INSERT INTO #{sm_table} (plugin_name, version) VALUES (#{self.class.plugin}, '#{version}')")
      end
    end

  end  # class Migrator
end  # module Goldberg
