require File.dirname(__FILE__) + '/../test_helper'

class SiteControllerTest < Test::Unit::TestCase
  include Goldberg::TestHelper

  def setup
    @p = Goldberg::Permission.find :first
  end
  
  def test_invalid_without_name
    site_controller = Goldberg::SiteController.new
    assert(!site_controller.valid?)
    assert(site_controller.errors.invalid?(:name))
    assert(!site_controller.save)
  end


  def test_uniqueness_of_name
    name_1 = 'THIS_IS_NAME_1'
    name_2 = 'THIS_IS_NAME_2'
    name_1.freeze
    name_2.freeze

    site_controller_1 = Goldberg::SiteController.new
    site_controller_1.permission = @p
    site_controller_2 = Goldberg::SiteController.new
    site_controller_2.permission = @p

    site_controller_1.name = name_1
    site_controller_2.name = name_2

    assert(site_controller_1.save)
    assert(site_controller_2.save)

    site_controller_2.name = name_1

    assert(!site_controller_2.save)
    assert(site_controller_2.errors.invalid?(:name))
  end

  
  #create so the classes method can be tested...
  class ThereShouldBeNoSuchRealClassNameGoldbergTestController < ApplicationController
  end
  
    
  def test_classes_finds_direct_controller_derivatives
    classes = Goldberg::SiteController.classes
    assert(classes.has_value?(SiteControllerTest::ThereShouldBeNoSuchRealClassNameGoldbergTestController))
  end

  
end
