require File.dirname(__FILE__) + '/../test_helper'

class MarkupStyleTest < Test::Unit::TestCase


  def test_invalid_without_name
    markup_style = MarkupStyle.new
    assert(!markup_style.valid?)
    assert(markup_style.errors.invalid?(:name))
    assert(!markup_style.save)
  end


  def test_uniqueness_of_name
    name_1 = 'THIS_IS_NAME_1'
    name_2 = 'THIS_IS_NAME_2'
    name_1.freeze
    name_2.freeze

    markup_style_1 = MarkupStyle.new
    markup_style_2 = MarkupStyle.new

    markup_style_1.name = name_1
    markup_style_2.name = name_2

    assert(markup_style_1.save)
    assert(markup_style_2.save)

    markup_style_2.name = name_1

    assert(!markup_style_2.save)
    assert(markup_style_2.errors.invalid?(:name))
  end


end
