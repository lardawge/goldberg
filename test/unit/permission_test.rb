require File.dirname(__FILE__) + '/../test_helper'

class PermissionTest < Test::Unit::TestCase
  include Goldberg::TestHelper

  def test_invalid_without_name
    permission = Goldberg::Permission.new
    assert(!permission.valid?)
    assert(permission.errors.invalid?(:name))
    assert(!permission.save)
  end


  def test_uniqueness_of_name
    name_1 = 'THIS_IS_NAME_1'
    name_2 = 'THIS_IS_NAME_2'
    name_1.freeze
    name_2.freeze

    permission_1 = Goldberg::Permission.new
    permission_2 = Goldberg::Permission.new

    permission_1.name = name_1
    permission_2.name = name_2

    assert(permission_1.save)
    assert(permission_2.save)

    permission_2.name = name_1

    assert(!permission_2.save)
    assert(permission_2.errors.invalid?(:name))
  end

end
