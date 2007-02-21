require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users

  def test_requires_name
    user = User.new
    assert(!user.valid?)
    assert(user.errors.invalid?(:name))
    assert(!user.save)
  end
  
  
  def test_name_unique
    name_1 = 'NAME1'
    name_2 = 'NAME2'
    name_1.freeze
    name_2.freeze
    
    user_1 = User.new(:name => name_1)
    user_2 = User.new(:name => name_2)
    
    assert(user_1.save)
    assert(user_2.save)
    
    user_2.name = name_1
    assert(!user_2.save)
    assert(!user_2.valid?)
    assert(user_2.errors.invalid?(:name))
  end
  
  
  def test_password_updated_on_save_when_clear_password_set
    user = User.new(:name => 'name')
    assert(user.save)
    
    saved_password = user.password
    saved_salt = user.password_salt
    
    user.clear_password = 'test123'
    assert(user.save)
    
    assert_not_equal(saved_password, user.password)
    assert_not_equal(saved_salt, user.password_salt)
    
    saved_password = user.password
    saved_salt = user.password_salt
    
    user.name = 'haha'
    assert(user.name)
    
    assert_equal(saved_password, user.password)
    assert_equal(saved_salt, user.password_salt)
  end
  
  
  def test_clear_password_set_nil_on_save
    new_pass = 'test123'
    new_pass.freeze
    
    user = User.new(:name => 'name')
    assert(user.save)
    
    user.clear_password = new_pass
    assert_equal(new_pass, user.clear_password)
    assert(user.save)
    assert_nil(user.clear_password)
  end
  
  
  def test_check_password
    first_pass = 'test'
    new_pass = 'test1'    
    first_pass.freeze
    new_pass.freeze
    
    assert_not_equal(first_pass, new_pass)
    
    user = User.new(:name => 'user')
    user.clear_password = first_pass
    assert(user.save)
    
    assert(user.check_password(first_pass))
    assert(!user.check_password(new_pass))
    
    user.clear_password = new_pass
    assert(user.save)
    
    assert(user.check_password(new_pass))
    assert(!user.check_password(first_pass))
  end
  
  
end
