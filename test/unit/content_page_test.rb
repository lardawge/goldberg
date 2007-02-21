require File.dirname(__FILE__) + '/../test_helper'

class ContentPageTest < Test::Unit::TestCase

  fixtures :content_pages, :permissions, :markup_styles


  def test_invalid_without_name
    content_page = ContentPage.new
    assert(!content_page.valid?)
    assert(content_page.errors.invalid?(:name))
    assert(!content_page.save)
  end


  def test_uniqueness_of_name
    name_1 = 'THIS_IS_NAME_1'
    name_2 = 'THIS_IS_NAME_2'
    name_1.freeze
    name_2.freeze

    content_page_1 = ContentPage.new
    content_page_2 = ContentPage.new

    content_page_1.name = name_1
    content_page_2.name = name_2

    assert(content_page_1.save)
    assert(content_page_2.save)

    content_page_2.name = name_1

    assert(!content_page_2.save)
    assert(content_page_2.errors.invalid?(:name))
  end


  def test_url_based_on_name
    name_1 = 'THIS_IS_NAME_1'
    name_2 = 'THIS_IS_NAME_2'
    name_1.freeze
    name_2.freeze

    expected_url_for_name_1 = '/THIS_IS_NAME_1'
    expected_url_for_name_2 = '/THIS_IS_NAME_2'
    expected_url_for_name_1.freeze
    expected_url_for_name_2.freeze

    content_page = ContentPage.new
    content_page.name = name_1
    content_page.save

    assert_equal(content_page.url, expected_url_for_name_1)
    assert_not_equal(content_page.url, expected_url_for_name_2)

    content_page.name = name_2
    content_page.save

    assert_equal(content_page.url, expected_url_for_name_2)
    assert_not_equal(content_page.url, expected_url_for_name_1)
  end


  def test_find_for_permission_returns_at_least_empty_array
    return_from_nil_call = ContentPage.find_for_permission(nil)
    assert(return_from_nil_call.kind_of?(Array))
    assert(return_from_nil_call.empty?)

    return_from_empty_array_call = ContentPage.find_for_permission([])
    assert(return_from_empty_array_call.kind_of?(Array))
    assert(return_from_empty_array_call.empty?)

    no_such_permission_id = -1
    no_such_permission_id.freeze

    #just to make sure the next assert does not fail simply because there
    #happen to be some content pages in the fixtures with this (illegal)
    #permission_id...
    assert(ContentPage.find_by_permission_id(no_such_permission_id).nil?)

    return_from_no_such_permission_id = ContentPage.find_for_permission([no_such_permission_id])
    assert(return_from_no_such_permission_id.kind_of?(Array))
    assert(return_from_no_such_permission_id.empty?)
  end


  def test_find_for_permission_finds_by_permission_ids_and_sorts_by_content_page_name
    dweezel_permission = permissions(:dweezel)

    should_be_first_in_dweezel = content_pages(:one_of_two_with_dweezel_permissions)
    should_be_second_in_dweezel = content_pages(:two_of_two_with_dweezel_permissions)
    expected_found_with_dweezel = [should_be_first_in_dweezel, should_be_second_in_dweezel]

    found_with_dweezel = ContentPage.find_for_permission([dweezel_permission.id])
    assert_equal(found_with_dweezel, expected_found_with_dweezel)

    doozle_permission = permissions(:doozle)

    should_be_first_in_doozle = content_pages(:one_of_one_with_doozle_permissions)
    expected_found_with_doozle = [should_be_first_in_doozle]

    found_with_doozle = ContentPage.find_for_permission([doozle_permission.id])
    assert_equal(found_with_doozle, expected_found_with_doozle)

    should_be_first_in_dweezel_and_doozle = content_pages(:one_of_two_with_dweezel_permissions)
    should_be_second_in_dweezel_and_doozle = content_pages(:one_of_one_with_doozle_permissions)
    should_be_third_in_dweezel_and_doozle = content_pages(:two_of_two_with_dweezel_permissions)

    expected_found_with_dweezel_and_doozle = [should_be_first_in_dweezel_and_doozle,
                                              should_be_second_in_dweezel_and_doozle,
                                              should_be_third_in_dweezel_and_doozle]

    found_with_dweezel_and_doozle = ContentPage.find_for_permission([dweezel_permission.id,
                                                                     doozle_permission.id])
    assert_equal(found_with_dweezel_and_doozle, expected_found_with_dweezel_and_doozle)
    found_with_doozle_and_dweezel = ContentPage.find_for_permission([doozle_permission.id,
                                                                     dweezel_permission.id])
    assert_equal(found_with_doozle_and_dweezel, expected_found_with_dweezel_and_doozle)
  end


  def test_content_html_with_no_markup_should_equal_content
    test_content = 'h1. This is some *test* _html_'
    test_content.freeze

    content_page = content_pages(:without_markup)
    content_page.content = test_content
    content_page.save!

    assert_equal(test_content, content_page.content_html)
  end


  def test_content_html_with_textile_markup
    test_content = 'h1. This is some *test* _html_'
    test_content.freeze

    content_page = content_pages(:with_textile_markup)
    content_page.content = test_content
    content_page.save!

    assert_equal(RedCloth.new(test_content).to_html(:textile), content_page.content_html)
    assert_not_equal(test_content, content_page.content_html)
  end


  def test_content_html_with_markdown_markup
    test_content = 'h1. This is some *test* _html_'
    test_content.freeze

    content_page = content_pages(:with_markdown_markup)
    content_page.content = test_content
    content_page.save!

    assert_equal(RedCloth.new(test_content).to_html(:markdown), content_page.content_html)
    assert_not_equal(test_content, content_page.content_html)
  end


  def test_before_save_caches_marked_up_content
    test_content_1 = 'h1. This is some *test* _html_'
    test_content_1.freeze
    test_content_1_textile = RedCloth.new(test_content_1).to_html(:textile)
    test_content_1_textile.freeze

    content_page = content_pages(:with_textile_markup)
    content_page.content = ''

    assert_not_equal(test_content_1, content_page.content_html)
    assert_not_equal(test_content_1_textile, content_page.content_html)
    assert_not_equal(test_content_1, content_page.content_cache)
    assert_not_equal(test_content_1_textile, content_page.content_cache)

    content_page.content = test_content_1

    assert_not_equal(test_content_1, content_page.content_html)
    assert_equal(test_content_1_textile, content_page.content_html)
    assert_not_equal(test_content_1, content_page.content_cache)
    assert_not_equal(test_content_1_textile, content_page.content_cache)

    assert(content_page.save)

    assert_not_equal(test_content_1, content_page.content_html)
    assert_equal(test_content_1_textile, content_page.content_html)
    assert_not_equal(test_content_1, content_page.content_cache)
    assert_equal(test_content_1_textile, content_page.content_cache)
  end


  def test_content_works_with_custom_accessor
    content_1 = 'test1'
    content_1.freeze

    content_page = ContentPage.new
    content_page.content = content_1
    content_page.name = 'testing_content_accessor'
    content_page.save!
    assert_equal(content_1, content_page.content)

    content_page_from_find = ContentPage.find(content_page.id)

    assert_equal(content_1, content_page_from_find.content)
  end


  def test_content_consistent_with_content_html
    test_content_1 = 'test 123'
    test_content_2 = 'test 234'
    test_content_1.freeze
    test_content_2.freeze

    content_page = content_pages(:without_markup)

    assert_not_equal(test_content_1, content_page.content)
    assert_not_equal(test_content_1, content_page.content_html)
    assert_equal(content_page.content_html, content_page.content)

    content_page.content = test_content_1

    assert_equal(test_content_1, content_page.content)
    assert_equal(test_content_1, content_page.content_html)
    assert_equal(content_page.content, content_page.content_html)

    assert(content_page.save)

    assert_equal(test_content_1, content_page.content)
    assert_equal(test_content_1, content_page.content_html)
    assert_equal(content_page.content, content_page.content_html)

    content_page.content = test_content_2

    assert_equal(test_content_2, content_page.content)
    assert_equal(test_content_2, content_page.content_html)
    assert_equal(content_page.content, content_page.content_html)
  end

end
