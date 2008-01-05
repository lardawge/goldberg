module Goldberg
  # Goldberg's TestHelper module loads Goldberg's bootstrap
  # environment for use in functional and integration testing.  It
  # also provides some methods for logging a user in and out.
  #
  # The fixtures are loaded from
  # RAILS_ROOT/vendor/plugins/goldberg/db.  By default this contains
  # the bootstrap that came with Goldberg.  However you can configure
  # your system (create roles, permissions, users, controllers/actions
  # and a menu) then dump a bootstrap that represents your
  # configuration using the Rake task:
  #
  #   rake goldberg:dump_bootstrap
  #
  # This offers an arguably more realistic approach than conventional
  # fixtures: tests are performed using a real Goldberg setup.
  # Furthermore dumping a bootstrap from your configured site allows
  # you to test your security in functional and integration tests: you
  # can log in and perform actions in your tests, and ensure that
  # actions and/or pages are appropriately allowed or forbidden based
  # on the security you have defined.
  module TestHelper

    def self.included(klass)
      # The first time this is included make sure the database is
      # up-to-date (especially applicable for PostgreSQL, for which the
      # schema is not dumped properly), then load Goldberg's fixtures.
      unless @already_done
        begin
          verbosity = ActiveRecord::Migration.verbose
          ActiveRecord::Migration.verbose = false
          Goldberg::Migrator.plugin_name = 'goldberg'
          Goldberg::Migrator.migrate
        rescue ActiveRecord::StatementInvalid
          # Must already exist.  Continue...
        ensure
          ActiveRecord::Migration.verbose = verbosity
        end

        fixture_path = File.dirname(__FILE__) + '/../../db'  # default
        # Goldberg prefers to use fixtures from its own test/fixtures dir
        if ( (caller.first =~ %r<vendor/plugins/goldberg/test>) &&
             File.exists?(File.dirname(__FILE__) + '/../../test/fixtures') )
          fixture_path = File.dirname(__FILE__) + '/../../test/fixtures'
        end
        # Load Goldberg's bootstrap data
        puts "Loading fixtures from '#{fixture_path}'..."
        klasses ||= Goldberg::Migration.goldberg_classes
        klasses.each do |klass|
          klass.delete_all
          Goldberg::Migration.load_for_class(klass, fixture_path)
        end
        puts "Done loading fixtures."
      else
        # Do nothing...
      end
      @already_done = true
    end

    # Set logged-in user (for functional testing)
    def login_user(user_name)
      user = Goldberg::User.find_by_name(user_name)
      @request.session[:goldberg] = {:user_id => (user ? user.id : nil)}
      Goldberg::AuthController.set_user(@request.session)
      @request.session[:last_time] = Time.now
    end

    # Form-based login (for integration testing)
    def form_login(user, password)
      post '/goldberg/auth/login', :login => {
        :name => user,
        :password => password
      }
    end

    # Form-based logout (for integration testing)
    def form_logout
      post '/goldberg/auth/logout'
    end

  end
end
