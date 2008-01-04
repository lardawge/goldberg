# Goldberg::Migrator is a plugin migration system based on
# PluginAWeek's (http://pluginaweek.org) plugin_migrations.  It allows
# plugins to have their own migration streams.  These can be made
# available as rake tasks that work similarly to Rails' "db:migrate"
# task, including respecting the VERSION environment variable.  See
# Goldberg's "goldberg:migrate" task.
# 
# This code is included in the Goldberg project in order to remove the
# dependency on the plugin_migrations gem, while retaining schema
# compatibilty so that users can use Goldberg alongside other plugins
# that utilise plugin_migrations.

module Goldberg
  module SchemaStatements
    def self.included(base) #:nodoc:
      base.class_eval do
        alias_method_chain :initialize_schema_information, :plugins
        alias_method_chain :dump_schema_information, :plugins
      end
    end
    
    # Creates the plugin schema info table
    def initialize_schema_information_with_plugins
      initialize_schema_information_without_plugins
      
      begin
        execute <<-EOS
CREATE TABLE #{Goldberg::Migrator.schema_info_table_name}
(plugin_name #{type_to_sql(:string)}, version #{type_to_sql(:integer)})
EOS
      rescue ActiveRecord::StatementInvalid
        # Schema has already been initialised?
      end
    end
    
    # Dumps the plugin schema info table as well as information about the
    # current plugin migrations
    def dump_schema_information_with_plugins
      schema_information = []
      
      dump = dump_schema_information_without_plugins
      dump && (schema_information << dump)
      
      begin
        plugins = ActiveRecord::Base.connection.select_all <<-EOS
SELECT * FROM #{Goldberg::Migrator.schema_info_table_name}
EOS
        plugins.each do |plugin|
          if (version = plugin['version'].to_i) > 0
            plugin_esc = ActiveRecord::Base.quote_value(plugin['plugin_name'])
            schema_information << %Q<
INSERT INTO #{Goldberg::Migrator.schema_info_table_name}
(plugin_name, version) VALUES (#{plugin_esc}, #{version})>
          end
        end
      rescue ActiveRecord::StatementInvalid 
        # No Schema Info
      end
      
      schema_information.join(";\n")
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
      
      def schema_info_table_name
        ActiveRecord::Base.table_name_prefix + 'plugin_schema_info' +
          ActiveRecord::Base.table_name_suffix
      end
      
      def current_version
        begin
          if result = ActiveRecord::Base.connection.select_one(%Q<
SELECT version FROM #{schema_info_table_name} WHERE plugin_name=#{plugin}>)
            result['version'].to_i
          else
            # No such plugin migrated yet?
            0
          end
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
      
    # Sets the version of the current plugin
    def set_schema_version(version)
      version = down? ? version.to_i - 1 : version.to_i
      
      if ActiveRecord::Base.connection.select_one <<-EOS
SELECT version FROM #{self.class.schema_info_table_name}
WHERE plugin_name = #{self.class.plugin}
EOS
        ActiveRecord::Base.connection.update <<-EOS
UPDATE #{self.class.schema_info_table_name} SET version = #{version}
WHERE plugin_name = #{self.class.plugin}
EOS
      else
        # We need to create the entry since it doesn't exist yet
        ActiveRecord::Base.connection.execute <<-EOS
INSERT INTO #{self.class.schema_info_table_name} (version, plugin_name)
VALUES (#{version}, #{self.class.plugin})
EOS
      end
    end

  end  # class Migrator
end  # module Goldberg
