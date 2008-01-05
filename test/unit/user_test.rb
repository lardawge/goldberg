require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  include Goldberg::TestHelper

  def setup
    @role = Goldberg::Role.find :first
  end
  
  def test_requires_name
    user = Goldberg::User.new
    assert(!user.valid?)
    assert(user.errors.invalid?(:name))
    assert(!user.save)
  end
  
  
  def test_name_unique
    name_1 = 'NAME1'
    name_2 = 'NAME2'
    name_1.freeze
    name_2.freeze
    
    user_1 = Goldberg::User.new(:name => name_1)
    user_1.role = @role
    user_1.clear_password = 'fred'
    user_2 = Goldberg::User.new(:name => name_2)
    user_2.role = @role
    user_2.clear_password = 'fred'
    
    assert(user_1.save)
    assert(user_2.save)
    
    user_2.name = name_1
    assert(!user_2.save)
    assert(!user_2.valid?)
    assert(user_2.errors.invalid?(:name))
  end
  
  
  def test_password_updated_on_save_when_clear_password_set
    user = Goldberg::User.new(:name => 'name')
    user.role = @role
    user.clear_password = 'fred'
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
    
    user = Goldberg::User.new(:name => 'name')
    user.role = @role
    assert(!user.save)
    
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
    
    user = Goldberg::User.new(:name => 'user')
    user.role =  @role
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
