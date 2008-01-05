require File.dirname(__FILE__) + '/../test_helper.rb'
require 'goldberg/content_pages_controller'
require 'goldberg/auth_controller'

# Re-raise errors caught by the controller.
class Goldberg::ContentPagesController; def rescue_action(e) raise e end; end

class ContentPagesControllerTest < Test::Unit::TestCase
  include Goldberg::TestHelper

  def setup
    @controller = Goldberg::ContentPagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_get_public_page
    get :view, :page_name => ['home']
    assert_response :success
  end

  def test_get_admin_page
    get :view, {:page_name => ['admin']}
    assert_response :redirect

    login_user('admin')
    get :view, {:page_name => ['admin']}
    assert_response :success
  end

end
