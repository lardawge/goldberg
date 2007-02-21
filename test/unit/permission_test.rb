require File.dirname(__FILE__) + '/../test_helper'

class PermissionTest < Test::Unit::TestCase
  fixtures :permissions, :roles, :roles_permissions

  def test_invalid_without_name
    permission = Permission.new
    assert(!permission.valid?)
    assert(permission.errors.invalid?(:name))
    assert(!permission.save)
  end


  def test_uniqueness_of_name
    name_1 = 'THIS_IS_NAME_1'
    name_2 = 'THIS_IS_NAME_2'
    name_1.freeze
    name_2.freeze

    permission_1 = Permission.new
    permission_2 = Permission.new

    permission_1.name = name_1
    permission_2.name = name_2

    assert(permission_1.save)
    assert(permission_2.save)

    permission_2.name = name_1

    assert(!permission_2.save)
    assert(permission_2.errors.invalid?(:name))
  end


  def test_find_for_role_finds_all_permissions_for_role_ids
    the_permissions = Permission.find_for_role([roles(:macbeth).id])
    assert(the_permissions.kind_of?(Array))
    assert(the_permissions.length == 2)
    assert(the_permissions.include?(permissions(:view_permission_for_macbeth_role)))
    assert(the_permissions.include?(permissions(:edit_permission_for_macbeth_role)))
    
    the_permissions = Permission.find_for_role([0]) #no such role
    assert_equal([], the_permissions)
  end
  
  
  def test_find_for_role_orders_by_permission_name
    the_permissions = Permission.find_for_role([roles(:macbeth).id])
    assert(the_permissions.kind_of?(Array))
    assert(the_permissions.length == 2)

    assert(the_permissions[0] == permissions(:edit_permission_for_macbeth_role))
    assert(the_permissions[1] == permissions(:view_permission_for_macbeth_role))
    
    #just to make sure it's actually interesting that these are ordered...
    
    assert(the_permissions[0].id > the_permissions[1].id)
  end
  
  
  def test_find_for_role_does_not_find_ancestor_permissions
    the_permissions = Permission.find_for_role([roles(:son_of_hamlet).id])
    
    assert(the_permissions.kind_of?(Array))
    assert(the_permissions.length == 2)
    
    assert(the_permissions.include?(permissions(:view_permission_for_son_of_hamlet_role)))
    assert(the_permissions.include?(permissions(:edit_permission_for_son_of_hamlet_role)))
    assert(!the_permissions.include?(permissions(:view_permission_for_hamlet_role)))
    assert(!the_permissions.include?(permissions(:edit_permission_for_hamlet_role)))

    #make sure the parent really has permissions...
    parent_permissions = Permission.find_for_role([roles(:hamlet).id])
    
    assert(parent_permissions.kind_of?(Array))
    assert(parent_permissions.length == 2)

    assert(parent_permissions.include?(permissions(:view_permission_for_hamlet_role)))
    assert(parent_permissions.include?(permissions(:edit_permission_for_hamlet_role)))
    assert(!parent_permissions.include?(permissions(:view_permission_for_son_of_hamlet_role)))
    assert(!parent_permissions.include?(permissions(:edit_permission_for_son_of_hamlet_role)))

    #make sure we're really testing different permissions...
    assert_not_equal(permissions(:view_permission_for_son_of_hamlet_role), 
                     permissions(:view_permission_for_hamlet_role))
    assert_not_equal(permissions(:edit_permission_for_son_of_hamlet_role), 
                     permissions(:edit_permission_for_hamlet_role))
  end
  
  
  def test_find_all_for_role_finds_ancestor_permissions_as_well
    the_permissions = Permission.find_all_for_role(roles(:son_of_hamlet))

    assert(the_permissions.kind_of?(Array))
    assert(the_permissions.length == 4)
    
    assert(the_permissions.include?(permissions(:view_permission_for_son_of_hamlet_role)))
    assert(the_permissions.include?(permissions(:edit_permission_for_son_of_hamlet_role)))
    assert(the_permissions.include?(permissions(:view_permission_for_hamlet_role)))
    assert(the_permissions.include?(permissions(:edit_permission_for_hamlet_role)))

    #make sure the parent really has permissions...
    parent_permissions = Permission.find_for_role([roles(:hamlet).id])
    
    assert(parent_permissions.kind_of?(Array))
    assert(parent_permissions.length == 2)

    assert(parent_permissions.include?(permissions(:view_permission_for_hamlet_role)))
    assert(parent_permissions.include?(permissions(:edit_permission_for_hamlet_role)))
    
    #make sure the other permissions came from the child...
    assert(!parent_permissions.include?(permissions(:view_permission_for_son_of_hamlet_role)))
    assert(!parent_permissions.include?(permissions(:edit_permission_for_son_of_hamlet_role)))

    #make sure we're really testing different permissions...
    assert_not_equal(permissions(:view_permission_for_son_of_hamlet_role), 
                     permissions(:view_permission_for_hamlet_role))
    assert_not_equal(permissions(:edit_permission_for_son_of_hamlet_role), 
                     permissions(:edit_permission_for_hamlet_role))
  end
  
  
  def test_find_all_for_role_does_not_find_descendent_permissions
    the_permissions = Permission.find_for_role([roles(:son_of_hamlet).id])
    
    assert(the_permissions.kind_of?(Array))
    assert(the_permissions.length == 2)
    
    assert(the_permissions.include?(permissions(:view_permission_for_son_of_hamlet_role)))
    assert(the_permissions.include?(permissions(:edit_permission_for_son_of_hamlet_role)))
    assert(!the_permissions.include?(permissions(:view_permission_for_hamlet_role)))
    assert(!the_permissions.include?(permissions(:edit_permission_for_hamlet_role)))

    parent_permissions = Permission.find_all_for_role(roles(:hamlet))
    
    assert(parent_permissions.kind_of?(Array))
    assert(parent_permissions.length == 2)

    assert(parent_permissions.include?(permissions(:view_permission_for_hamlet_role)))
    assert(parent_permissions.include?(permissions(:edit_permission_for_hamlet_role)))
    assert(!parent_permissions.include?(permissions(:view_permission_for_son_of_hamlet_role)))
    assert(!parent_permissions.include?(permissions(:edit_permission_for_son_of_hamlet_role)))

    #make sure we're really testing different permissions...
    assert_not_equal(permissions(:view_permission_for_son_of_hamlet_role), 
                     permissions(:view_permission_for_hamlet_role))
    assert_not_equal(permissions(:edit_permission_for_son_of_hamlet_role), 
                     permissions(:edit_permission_for_hamlet_role))
  end
  
  
  def test_find_all_for_role_orders_by_permission_name
    the_permissions = Permission.find_all_for_role(roles(:son_of_hamlet))

    assert(the_permissions.kind_of?(Array))
    assert(the_permissions.length == 4)
    
    assert_equal(permissions(:edit_permission_for_hamlet_role), the_permissions[0])
    assert_equal(permissions(:edit_permission_for_son_of_hamlet_role), the_permissions[1])
    assert_equal(permissions(:view_permission_for_hamlet_role), the_permissions[2])
    assert_equal(permissions(:view_permission_for_son_of_hamlet_role), the_permissions[3])
  end
  
  
  def test_find_not_for_role_finds_all_permissions_not_attached_to_role
    all_permissions = Permission.find(:all).sort {|x, y| x.id <=> y.id}
    permissions_for_hamlet = Permission.find_for_role(roles(:hamlet)).sort {|x, y| x.id <=> y.id}
    permissions_for_macbeth = Permission.find_for_role(roles(:macbeth)).sort {|x, y| x.id <=> y.id}
    
    assert_not_equal(permissions_for_macbeth, permissions_for_hamlet)
    assert_not_equal(permissions_for_macbeth, all_permissions)
    assert_not_equal(permissions_for_hamlet, all_permissions)
    
    expected_not_for_macbeth = all_permissions.reject do |p|
      permissions_for_macbeth.include?(p)
    end.sort {|x, y| x.id <=> y.id}
    
    actual_not_for_macbeth = Permission.find_not_for_role(roles(:macbeth).id).sort {|x, y| x.id <=> y.id}
    
    assert_not_equal(expected_not_for_macbeth, all_permissions)
    assert_not_equal(actual_not_for_macbeth, all_permissions)
    assert_not_equal(expected_not_for_macbeth, permissions_for_macbeth)
    assert_equal(expected_not_for_macbeth, actual_not_for_macbeth)
    
    expected_not_for_hamlet = all_permissions.reject do |p|
      permissions_for_hamlet.include?(p)
    end.sort {|x, y| x.id <=> y.id}
    
    actual_not_for_hamlet = Permission.find_not_for_role(roles(:hamlet).id).sort {|x, y| x.id <=> y.id}
    
    assert_not_equal(expected_not_for_hamlet, all_permissions)
    assert_not_equal(actual_not_for_hamlet, all_permissions)
    assert_not_equal(expected_not_for_hamlet, permissions_for_hamlet)
    assert_equal(expected_not_for_hamlet, actual_not_for_hamlet)
  end
  

  def test_find_not_for_role_orders_by_name
    roles_to_test = [:macbeth, :hamlet, :son_of_hamlet]
    
    roles_to_test.each do |role|
      res = Permission.find_not_for_role(role)
      assert_equal(res.sort {|x, y| x.name <=> y.name}, res)
    end
  end

  
  def test_find_not_for_role_does_not_take_hierarchy_into_account
    assert_equal(roles(:hamlet).id, roles(:son_of_hamlet).parent_id)
    
    all_permissions = Permission.find(:all).sort {|x, y| x.id <=> y.id}
    permissions_for_hamlet = Permission.find_for_role(roles(:hamlet)).sort {|x, y| x.id <=> y.id}
    permissions_for_son_of_hamlet = Permission.find_for_role(roles(:son_of_hamlet)).sort {|x, y| x.id <=> y.id}
    
    assert_not_equal(permissions_for_son_of_hamlet, permissions_for_hamlet)
    assert_not_equal(permissions_for_son_of_hamlet, all_permissions)
    assert_not_equal(permissions_for_hamlet, all_permissions)
    
    expected_not_for_son_of_hamlet = all_permissions.reject do |p|
      permissions_for_son_of_hamlet.include?(p)
    end.sort {|x, y| x.id <=> y.id}
    
    actual_not_for_son_of_hamlet = Permission.find_not_for_role(roles(:son_of_hamlet).id).sort {|x, y| x.id <=> y.id}
    
    assert_not_equal(expected_not_for_son_of_hamlet, all_permissions)
    assert_not_equal(actual_not_for_son_of_hamlet, all_permissions)
    assert_not_equal(expected_not_for_son_of_hamlet, permissions_for_son_of_hamlet)
    assert_equal(expected_not_for_son_of_hamlet, actual_not_for_son_of_hamlet)
    
    expected_not_for_hamlet = all_permissions.reject do |p|
      permissions_for_hamlet.include?(p)
    end.sort {|x, y| x.id <=> y.id}
    
    actual_not_for_hamlet = Permission.find_not_for_role(roles(:hamlet).id).sort {|x, y| x.id <=> y.id}
    
    assert_not_equal(expected_not_for_hamlet, all_permissions)
    assert_not_equal(actual_not_for_hamlet, all_permissions)
    assert_not_equal(expected_not_for_hamlet, permissions_for_hamlet)
    assert_equal(expected_not_for_hamlet, actual_not_for_hamlet)
  end

end
