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
  
end  # module GoldbergMigration
