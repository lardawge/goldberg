require 'active_record/connection_adapters/postgresql_adapter'

# Set the appropriate table prefix using AR's "set_table_name" 

# This module is included in all Goldberg's model classes.  On load it
# adds the prefix "goldberg." to all table names if the connection is
# to PostgreSQL; otherwise it adds the prefix "g_".

module Goldberg
  module Model

    def self.included(base)
      base.class_eval do
        
        def self.prefix
          if not @prefix
            if self.connection.class.to_s == 
                'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
              @prefix = 'goldberg.'
            else
              @prefix = 'goldberg_'
            end
          end
          @prefix
        end
        
        (table_name =~ /goldberg/) ||
          (set_table_name "#{self.prefix}#{self.table_name}")
      end
    end
    
  end


  # Fixes the "pk_and_sequence_for" method in the PostgreSQL adapter, to
  # include namespace support.

  module PostgreSQL
    def self.included(base)
      base.class_eval do
        alias_method :pk_and_sequence_for_without_goldberg, :pk_and_sequence_for
        alias_method :pk_and_sequence_for, :pk_and_sequence_for_with_goldberg
      end
    end

    # (From
    # vendor/rails/activerecord/lib/active_record/connection_adapters/
    # postgresql_adapter.rb)  

    def pk_and_sequence_for_with_goldberg(table)
      # First try looking for a sequence with a dependency on the
      # given table's primary key.
      result = query(<<-end_sql, 'PK and serial sequence')[0]
          SELECT attr.attname, name.nspname, seq.relname
          FROM pg_class      seq,
               pg_attribute  attr,
               pg_depend     dep,
               pg_namespace  name,
               pg_constraint cons
          WHERE seq.oid           = dep.objid
            AND seq.relnamespace  = name.oid
            AND seq.relkind       = 'S'
            AND attr.attrelid     = dep.refobjid
            AND attr.attnum       = dep.refobjsubid
            AND attr.attrelid     = cons.conrelid
            AND attr.attnum       = cons.conkey[1]
            AND cons.contype      = 'p'
            AND dep.refobjid      = '#{table}'::regclass
    end_sql

      if result.nil? or result.empty?
        # If that fails, try parsing the primary key's default value.
        # Support the 7.x and 8.0 nextval('foo'::text) as well as
        # the 8.1+ nextval('foo'::regclass).
        # TODO: assumes sequence is in same schema as table.
        result = query(<<-end_sql, 'PK and custom sequence')[0]
        SELECT attr.attname, name.nspname, split_part(def.adsrc, '''', 2)
        FROM pg_class       t
        JOIN pg_namespace   name ON (t.relnamespace = name.oid)
        JOIN pg_attribute   attr ON (t.oid = attrelid)
        JOIN pg_attrdef     def  ON (adrelid = attrelid AND adnum = attnum)
        JOIN pg_constraint  cons ON (conrelid = adrelid AND adnum = conkey[1])
        WHERE t.oid = '#{table}'::regclass
          AND cons.contype = 'p'
          AND def.adsrc ~* 'nextval'
      end_sql
      end
      # check for existence of . in sequence name as in public.foo_sequence.  if it does not exist, return unqualified sequence
      # We cannot qualify unqualified sequences, as rails doesn't qualify any table access, using the search path
      # Commented out (DN):
      # [result.first, result.last]

      # Added (DN):
      # The above consideration is irrelevant.  PostgreSQL
      # databases always have tables in schemas, so specifying a schema
      # (even if it is "public") is valid; and in the case where schemas
      # *are* in use (using 'set_table_name' to set a schema on a model)
      # the schema path is *required*, otherwise INSERTs are broken.

      [ result[0], "#{result[1]}.#{result[2]}" ]
    rescue
      nil
    end
    
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
  include Goldberg::PostgreSQL
end
