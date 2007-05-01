module GoldbergMigration 

  def self.included(base)
    base.class_eval do
      
      def self.prefix
        if not @prefix
          if self.pg_conn?
            self.create_goldberg_schema
            @prefix = 'goldberg.'
          else
            @prefix = 'goldberg_'
          end
        end
        @prefix
      end
      
      def self.pg_conn?
        ActiveRecord::Base.connection.class.to_s == 
          'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
      end
      
      def self.goldberg_schema_exists?
        if self.pg_conn?
          count = ActiveRecord::Base.connection.select_value <<-END
SELECT COUNT(*) FROM pg_namespace WHERE nspname = 'goldberg'
END
          count.to_i > 0
        else
          false
        end
      end
      
      def self.create_goldberg_schema
        if self.pg_conn? and not self.goldberg_schema_exists?
          ActiveRecord::Base.connection.execute <<-END
CREATE SCHEMA goldberg
END
        end
      end
      
      def self.drop_goldberg_schema
        if self.pg_conn? and self.goldberg_schema_exists?
          ActiveRecord::Base.connection.execute <<-END
DROP SCHEMA goldberg
END
        end
      end
      
    end  # class_eval
  end  # self.included
  

  def self.load_bootstrap
    self.goldberg_classes.each do |klass|
      self.load_for_class klass, "#{File.dirname(__FILE__)}/../db"
    end
  end

  def self.dump_bootstrap
    self.goldberg_classes.each do |klass|
      self.dump_for_class klass, "#{File.dirname(__FILE__)}/../db"
    end
  end

  def self.goldberg_classes
    return [ Goldberg::Permission, Goldberg::SiteController, 
             Goldberg::ContentPage, Goldberg::ControllerAction,
             Goldberg::MenuItem, Goldberg::Role,
             Goldberg::RolesPermission, Goldberg::SystemSettings,
             Goldberg::User ]
  end
  
  def self.dump_for_class(klass, dest)
    filename = "#{dest}/#{klass.to_s.sub(/^Goldberg::/, '')}.yml"
    records = klass.find(:all)
    File.open(filename, 'w') do |out|  
      YAML.dump(records, out)
    end
  end
  
  def self.load_for_class(klass, src)
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
  
end  # module GoldbergMigration
