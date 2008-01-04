require File.dirname(__FILE__) + '/../test_helper'

class MenuItemTest < Test::Unit::TestCase
  include Goldberg::TestHelper
  
  def test_name_is_unique
    name_1 = 'THIS_IS_NAME_1'
    name_2 = 'THIS_IS_NAME_2'
    name_1.freeze
    name_2.freeze

    menu_item_1 = Goldberg::MenuItem.new(:content_page_id => 1)
    menu_item_2 = Goldberg::MenuItem.new(:content_page_id => 1)

    menu_item_1.name = name_1
    menu_item_1.label = 'This is name 1'
    menu_item_2.name = name_2
    menu_item_2.label = 'This is name 2'

    assert(menu_item_1.save)
    assert(menu_item_2.save)

    menu_item_2.name = name_1

    assert(!menu_item_2.save)
    assert(menu_item_2.errors.invalid?(:name))
  end

  
  def test_name_is_required
    mi = Goldberg::MenuItem.new(:content_page_id => 1)
    assert(!mi.valid?)
    assert(mi.errors.invalid?(:name))
    assert(!mi.save)
  end
  
  
  def test_must_have_content_page_or_controller_action
    mi = Goldberg::MenuItem.new(:name => 'test', :label => 'Test')
    assert(!mi.valid?)
    assert(mi.errors.invalid?(:content_page_id))
    assert(mi.errors.invalid?(:controller_action_id))
    assert(!mi.save)
  end
      
end
