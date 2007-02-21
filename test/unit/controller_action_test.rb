require File.dirname(__FILE__) + '/../test_helper'

class ControllerActionTest < Test::Unit::TestCase
  fixtures :controller_actions, :site_controllers, :permissions
  
  
  def test_name_required
    ca = ControllerAction.new
    assert(!ca.valid?)
    assert(ca.errors.invalid?(:name))
    assert(!ca.save)
  end
  
  
  def test_name_unique_within_scope_of_site_controller
    name_1 = "NAME1"
    name_2 = "NAME2"
    name_1.freeze
    name_2.freeze
    
    site_controller_id_1 = 1
    site_controller_id_2 = 2
    
    ca1 = ControllerAction.new(:name => name_1, :site_controller_id => site_controller_id_1)
    ca2 = ControllerAction.new(:name => name_2, :site_controller_id => site_controller_id_1)
    
    assert(ca1.save)
    assert(ca2.save)
    
    ca2.name = name_1
    assert(!ca2.valid?)
    assert(ca2.errors.invalid?(:name))
    assert(!ca2.save)
    
    ca2.site_controller_id = site_controller_id_2
    assert(ca2.valid?)
    assert(!ca2.errors.invalid?(:name))
    assert(ca2.save)
  end
  
  
  def test_effective_permission_id_returns_permission_id_if_non_nil
    sprocket_edit = controller_actions(:sprocket_edit)
    assert(sprocket_edit.permission_id)
    assert_equal(sprocket_edit.permission_id, sprocket_edit.effective_permission_id)
    assert_not_equal(site_controllers(:sprocket_controller).permission_id, sprocket_edit.effective_permission_id)
  end


  def test_effective_permission_id_returns_controllers_permission_id_if_nil
    sprocket_view = controller_actions(:sprocket_view)
    assert_nil(sprocket_view.permission_id)
    assert_not_equal(sprocket_view.permission_id, sprocket_view.effective_permission_id)
    assert_equal(site_controllers(:sprocket_controller).permission_id, sprocket_view.effective_permission_id)
  end
  
  
  def test_fullname_returns_controller_and_action_name_if_there_is_a_controller
    sprocket_view = controller_actions(:sprocket_view)
    assert_equal("#{site_controllers(:sprocket_controller).name}: #{sprocket_view.name}",
                 sprocket_view.fullname)
    assert_not_equal(sprocket_view.name, sprocket_view.fullname)
  end
  
  
  def test_fullname_returns_action_name_only_if_no_controller
    sprocket_view = controller_actions(:sprocket_view)
    fullname_with_controller = sprocket_view.fullname
    assert_not_equal(sprocket_view.name, fullname_with_controller)
    sprocket_view.site_controller_id = 0
    sprocket_view.save
    assert_not_equal(sprocket_view.fullname, fullname_with_controller)
    assert_equal(sprocket_view.name, sprocket_view.fullname)
  end
  
  
  def test_url
    expected_sprocket_view = '/sprocket_controller/sprocket_view'
    expected_widget_edit = '/widget_controller/widget_edit'
    expected_sprocket_view.freeze
    expected_widget_edit.freeze
    
    sprocket_view = controller_actions(:sprocket_view)
    assert_equal(expected_sprocket_view, sprocket_view.url)
    assert_not_equal(controller_actions(:sprocket_edit).url, sprocket_view.url)
    
    widget_edit = controller_actions(:widget_edit)
    assert_equal(expected_widget_edit, widget_edit.url)
    assert_not_equal(controller_actions(:widget_view).url, widget_edit.url)
  end
  
  
  def test_actions_allowed
    flunk('Waiting to write pending decision on MenuItem and ControllerAction revisions')
  end
  
  
  def test_find_for_permission_returns_empty_array_when_passed_nil
    assert_equal([], ControllerAction.find_for_permission(nil))
  end
  
  
  def test_find_for_permission_returns_empty_array_when_passed_empty_array
    assert_equal([], ControllerAction.find_for_permission([]))
  end
  
  
  def test_find_for_permission_does_not_take_into_account_controller_permission_id
    cas_for_sprocket_edit = ControllerAction.find_for_permission([permissions(:sprocket_edit_permission).id])
    assert(cas_for_sprocket_edit.length == 1)
    assert(cas_for_sprocket_edit[0] == controller_actions(:sprocket_edit))
    assert_equal(permissions(:sprocket_edit_permission).id, controller_actions(:sprocket_edit).permission_id)
    assert_not_equal(permissions(:sprocket_edit_permission).id, controller_actions(:sprocket_edit).controller.permission_id)

    cas_for_sprocket_view = ControllerAction.find_for_permission([permissions(:sprocket_view_permission).id])
    assert_equal([], cas_for_sprocket_view)
    assert_nil(controller_actions(:sprocket_view).permission_id)
    assert_equal(permissions(:sprocket_view_permission).id, controller_actions(:sprocket_view).controller.permission_id)
  end
  
  
  def test_find_for_permission_orders_results_by_name
    cas_for_test_disordered_ca = 
      ControllerAction.find_for_permission([permissions(:test_disordered_controller_actions_permission).id])
    assert_equal(cas_for_test_disordered_ca, cas_for_test_disordered_ca.sort {|x, y| x.name <=> y.name})
    assert_not_equal(cas_for_test_disordered_ca, cas_for_test_disordered_ca.sort {|x, y| x.id <=> y.id})
  end
  
end
