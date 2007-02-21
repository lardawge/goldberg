require File.dirname(__FILE__) + '/../test_helper'

class MenuItemTest < Test::Unit::TestCase
  #not using fixtures because of the sensitivity of the menu item chain tests...
  #rather use the fixtures for other, higher level tests.
  #fixtures :menu_items

  
  def test_name_is_unique
    name_1 = 'THIS_IS_NAME_1'
    name_2 = 'THIS_IS_NAME_2'
    name_1.freeze
    name_2.freeze

    menu_item_1 = MenuItem.new(:content_page_id => 1)
    menu_item_2 = MenuItem.new(:content_page_id => 1)

    menu_item_1.name = name_1
    menu_item_2.name = name_2

    assert(menu_item_1.save)
    assert(menu_item_2.save)

    menu_item_2.name = name_1

    assert(!menu_item_2.save)
    assert(menu_item_2.errors.invalid?(:name))
  end

  
  def test_name_is_required
    mi = MenuItem.new(:content_page_id => 1)
    assert(!mi.valid?)
    assert(mi.errors.invalid?(:name))
    assert(!mi.save)
  end
  
  
  def test_must_have_content_page_or_controller_action
    mi = MenuItem.new(:name => 'test')
    assert(!mi.valid?)
    assert(mi.errors.invalid?(:content_page_id))
    assert(mi.errors.invalid?(:controller_action_id))
    assert(!mi.save)
  end

  
  def test_above_with_parent
    parent = MenuItem.new(:name => 'parent', :content_page_id => 1)
    assert(parent.save)
    
    mi1 = MenuItem.new(:name => 'mi1',
                       :content_page_id => 1,
                       :parent_id => parent.id,
                       :seq => 1)
    assert(mi1.save)
    
    mi2 = MenuItem.new(:name => 'mi2',
                       :content_page_id => 1,
                       :parent_id => parent.id,
                       :seq => 2)
    assert(mi2.save)
    
    assert_equal(mi1, mi2.above)
    assert_nil(mi1.above)
  end
  
  
  def test_above_without_parent
    mi1 = MenuItem.new(:name => 'mi1',
                       :content_page_id => 1,
                       :seq => 1)
    assert(mi1.save)
    
    mi2 = MenuItem.new(:name => 'mi2',
                       :content_page_id => 1,
                       :seq => 2)
    assert(mi2.save)
    
    assert_equal(mi1, mi2.above)
    assert_nil(mi1.above)
  end

  
  def test_below_with_parent
    parent = MenuItem.new(:name => 'parent', :content_page_id => 1)
    assert(parent.save)
    
    mi1 = MenuItem.new(:name => 'mi1',
                       :parent_id => parent.id,
                       :content_page_id => 1,
                       :seq => 1)
    assert(mi1.save)
    
    mi2 = MenuItem.new(:name => 'mi2',
                       :parent_id => parent.id,
                       :content_page_id => 1,
                       :seq => 2)
    assert(mi2.save)
    
    assert_equal(mi2, mi1.below)
    assert_nil(mi2.below)
  end
  
  
  def test_below_without_parent
    mi1 = MenuItem.new(:name => 'mi1',
                       :content_page_id => 1,
                       :seq => 1)
    assert(mi1.save)
    
    mi2 = MenuItem.new(:name => 'mi2',
                       :content_page_id => 1,
                       :seq => 2)
    assert(mi2.save)
    
    assert_equal(mi2, mi1.below)
    assert_nil(mi2.below)
  end
  
  
  def test_above_returns_nil_with_unpacked_seqs
    mi1 = MenuItem.new(:name => 'mi1',
                       :content_page_id => 1,
                       :seq => 1)
    assert(mi1.save)
    
    mi2 = MenuItem.new(:name => 'mi2',
                       :content_page_id => 1,
                       :seq => 3)
    assert(mi2.save)
    
    assert_nil(mi2.above)
    assert_nil(mi1.above)
  end

  
  def test_below_returns_nil_with_unpacked_seqs
    mi1 = MenuItem.new(:name => 'mi1',
                       :content_page_id => 1,
                       :seq => 1)
    assert(mi1.save)
    
    mi2 = MenuItem.new(:name => 'mi2',
                       :content_page_id => 1,
                       :seq => 3)
    assert(mi2.save)
    
    assert_nil(mi1.below)
    assert_nil(mi2.below)
  end
  
  
  def test_repack_with_parent
    parent = MenuItem.new(:name => 'parent', 
                          :content_page_id => 1)
    assert(parent.save)
    
    mi1 = MenuItem.new(:name => 'mi1',
                       :parent_id => parent.id,
                       :content_page_id => 1,
                       :seq => 3)
    assert(mi1.save)
    
    mi2 = MenuItem.new(:name => 'mi2',
                       :parent_id => parent.id,
                       :content_page_id => 1,
                       :seq => 7)
    assert(mi2.save)
    
    MenuItem.repack(parent.id)
    
    mi1_from_db = MenuItem.find(mi1.id)
    mi2_from_db = MenuItem.find(mi2.id)
    
    assert_equal(1, mi1_from_db.seq)
    assert_equal(2, mi2_from_db.seq)
    
    #make sure it only changed seq...
    assert_not_equal(mi1_from_db.attributes, mi1.attributes)
    assert_not_equal(mi2_from_db.attributes, mi2.attributes)
    
    mi1.seq = 1
    mi2.seq = 2
    
    assert_equal(mi1_from_db.attributes, mi1.attributes)
    assert_equal(mi2_from_db.attributes, mi2.attributes)    
  end
  
  
  def test_repack_without_parent
    mi1 = MenuItem.new(:name => 'mi1',
                       :content_page_id => 1,
                       :seq => 3)
    assert(mi1.save)
    
    mi2 = MenuItem.new(:name => 'mi2',
                       :content_page_id => 1,
                       :seq => 7)
    assert(mi2.save)
    
    MenuItem.repack(nil)
    
    mi1_from_db = MenuItem.find(mi1.id)
    mi2_from_db = MenuItem.find(mi2.id)
    
    assert_equal(1, mi1_from_db.seq)
    assert_equal(2, mi2_from_db.seq)
    
    #make sure it only changed seq...
    assert_not_equal(mi1_from_db.attributes, mi1.attributes)
    assert_not_equal(mi2_from_db.attributes, mi2.attributes)
    
    mi1.seq = 1
    mi2.seq = 2
    
    assert_equal(mi1_from_db.attributes, mi1.attributes)
    assert_equal(mi2_from_db.attributes, mi2.attributes)    
  end
  
  
  def test_items_for_permission
    flunk('Waiting to write pending decision on MenuItem and ControllerAction revisions')
  end
    
end
