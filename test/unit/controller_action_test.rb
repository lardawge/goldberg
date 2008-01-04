require File.dirname(__FILE__) + '/../test_helper'

class ControllerActionTest < Test::Unit::TestCase
  include Goldberg::TestHelper

  def setup
    # Some associated records (two of each will do)
    (@sc1, @sc2) = Goldberg::SiteController.find :all
    (@p1, @p2) = Goldberg::Permission.find :all
  end
  
  def test_no_fields
    ca = Goldberg::ControllerAction.new
    assert !ca.valid?
    # name, and site_controller_id are compulsory
    [:name, :site_controller_id].each do |attr|
      assert ca.errors.on(attr)
    end
  end

  def test_minimal_fields
    ca = Goldberg::ControllerAction.new(:name => 'test')
    ca.site_controller = @sc1
    assert ca.save
    
    # All fields
    ca.permission = @p1
    assert ca.save
  end

  def test_all_fields
    ca = Goldberg::ControllerAction.new(:name => 'test')
    ca.site_controller = @sc1
    ca.permission = @p1
    assert ca.save
  end    
  
  # The name of the controller action should be unique within the
  # scope of the site controller.
  def test_name_unique_within_scope_of_site_controller
    ca1 = Goldberg::ControllerAction.new(:name => 'test')
    ca2 = Goldberg::ControllerAction.new(:name => 'test')
    ca1.site_controller = @sc1
    ca2.site_controller = @sc1
    ca1.save

    # Error: name not unique within scope of controller
    assert !ca2.save
    assert ca2.errors.on(:name)

    # Should work: same name, different controllers
    ca2.site_controller = @sc2
    assert ca2.save

    # Should work: different names, same controller
    ca2.name = 'test2'
    ca2.site_controller = @sc1
    assert ca2.save
  end

  # The effective permission is the permission of the controller
  # action, if specified; otherwise it is the permission of the
  # action's site controller.
  def test_effective_permission
    # Make sure we know the permission on the site controller
    @sc1.permission = @p1
    @sc1.save!
    
    ca = Goldberg::ControllerAction.new(:name => 'test')
    ca.site_controller = @sc1
    ca.save!

    # No explicit permission: effective permission should be the same
    # as site controller
    assert_nil ca.permission
    assert_equal @p1.id, ca.effective_permission.id

    # Explicit permission: should override permission of site
    # controller
    ca.permission = @p2
    ca.save!
    assert_not_nil ca.permission
    assert_equal @p2.id, ca.effective_permission.id
  end
end
