require File.dirname(__FILE__) + '/../test_helper'

class ContentPageTest < Test::Unit::TestCase
  include Goldberg::TestHelper

  def setup
    @permission = Goldberg::Permission.find :first
  end

  def test_all_fields
    page = Goldberg::ContentPage.new(:name => 'test', :title => 'A test')
    page.permission = @permission
    page.markup_style = 'Raw HTML'
    page.content = 'This is a test'
    assert page.save
  end

  # Test that HTML content is generated when it's accessed
  def test_content_cached_on_access
    page = new_page()
    page.content = 'This is a test'
    # No content yet
    assert_nil page.content_cache
    # Calling #content_html triggers HTML generation
    assert_not_nil page.content_html
    assert_not_nil page.content_cache
  end

  # Test that HTML content is generated when the page is saved
  def test_content_cached_on_save
    page = new_page()
    page.content = 'This is a test'
    # No content yet
    assert_nil page.content_cache
    page.save
    # Saving triggers HTML generation
    assert_not_nil page.content_cache
  end

  def test_minimal_fields
    page = Goldberg::ContentPage.new(:name => 'test', :title => 'A test')
    page.permission = @permission
    assert page.save
  end

  def test_no_fields
    page = Goldberg::ContentPage.new
    assert !page.valid?
    # name, title and permission_id are compulsory
    [:name, :title, :permission_id].each do |attr|
      assert page.errors.on(attr)
    end
  end

  # Test that name is unique
  def test_uniqueness_of
    # Create a page named 'test' and save it
    page1 = new_page()
    assert page1.save

    # Duplicate page name won't work
    page2 = new_page()
    assert !page2.save
    assert page2.errors.on(:name)

    # Fix name and it should work
    page2.name = 'test2'
    assert page2.save
  end

  # Test that the URL generated for the page equals the name preceded
  # with a slash
  def test_url_generation
    page = new_page()
    assert_equal page.url, '/test'
  end

    
  protected

  def new_page
    page = Goldberg::ContentPage.new(:name => 'test',
                                     :title => 'This is a test')
    page.permission = @permission
    return page
  end
end
