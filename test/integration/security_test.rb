require "#{File.dirname(__FILE__)}/../test_helper"


# (Also need to test for pending registration confirmation, and for
# session expiry.)

class SecurityTest < ActionController::IntegrationTest
  include Goldberg::TestHelper

  # Public user can execute public actions, but when they try
  # executing an administrator action they are redirected to login.
  def test_action_security
    # A public action
    get '/goldberg/auth/login'
    assert_response :success
    # An administrator action
    get '/goldberg/users/list'
    assert_redirected_to_login

    form_login('admin', 'admin')

    get '/goldberg/users/list'
    assert_response :success

    form_logout

    get '/goldberg/users/list'
    assert_redirected_to_login
  end

  # When a user with insufficient rights tries to access a page or
  # action they don't get redirected to login: they get redirected to
  # the "denied" page.
  def test_insufficient_security
    old_count = Goldberg::User.count
    form_login('admin', 'admin')
    post '/goldberg/users/create', :user => {
      :name => 'fred',
      :fullname => 'Fred Bloggs',
      :role_id => '2',  # "Member"
      :clear_password => 'fred',
      :confirm_password => 'fred',
    }
    # User was created OK
    assert_equal (old_count + 1), Goldberg::User.count

    # Logout, then login as new user
    form_logout
    form_login('fred', 'fred')
    assert_not_nil session[:goldberg][:user_id]

    # An administrator action: denied
    get '/goldberg/users/list'
    assert_redirected_to :permission_denied_page
    # An administrator page: denied
    get '/admin'
    assert_redirected_to :permission_denied_page
  end
  
  # Public user can view public pages, but when they try accessing an
  # administrator page they are redirected to login.
  def test_page_security
    # A public page
    get '/home'
    assert_response :success
    # An administrator page
    get '/admin'
    assert_redirected_to_login

    form_login('admin', 'admin')
    
    get '/admin'
    assert_response :success

    form_logout

    get '/admin'
    assert_redirected_to_login
  end

  # If a public user tries to access a resource for which they lack
  # authorisation, after logging in they should be redirected to that
  # resource.
  def test_pending_request
    get '/goldberg/users/list'
    assert_redirected_to_login

    form_login('admin', 'admin')
    assert_match /goldberg\/users\/list/, response.redirected_to
  end

  # User should be redirected to the session expired page if they
  # remain inactive longer than the session timeout in System
  # Settings.
  def test_session_expiry
    # Set the timeout really short
    settings = Goldberg::SystemSettings.find :first
    settings.session_timeout = 3  # Three seconds should be ample
    settings.save!

    form_login('admin', 'admin')
    get '/site_admin'
    assert_response :success

    # Wait longer than the timeout
    sleep 4
    get '/site_admin'
    assert_redirected_to :session_expired_page
  end
  
  # User is not logged in if password is wrong
  def test_wrong_password
    form_login('admin', 'foobar')
    assert_nil session[:goldberg][:user_id]
  end
  
  protected

  # A user who was not logged in was redirected to the login page
  # because they tried accessing an action or page for which they
  # lacked authorisation.
  def assert_redirected_to_login
    assert_equal({ :controller => 'goldberg/auth',
                   :action => 'login' },
                 response.redirected_to)
  end    

  # User was redirected to one of the standard Goldberg pages, as
  # specified by :page_name.
  def assert_redirected_to(page_name)
    assert_match(/#{Goldberg.settings.send(page_name).url}$/,
                 response.redirected_to)
  end
end
