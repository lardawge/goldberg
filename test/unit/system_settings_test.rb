require File.dirname(__FILE__) + '/../test_helper'

class SystemSettingsTest < Test::Unit::TestCase
  fixtures :roles, :markup_styles, :content_pages


  def test_public_role
    public_role = roles(:public)
    ss = SystemSettings.create(:public_role_id => public_role.id)
    assert_equal(public_role, ss.public_role)
  end


  def test_public_role_raises_when_role_not_found
    ss = SystemSettings.create
    assert_raise(ActiveRecord::RecordNotFound) {ss.public_role}
  end


  def test_default_markup_style
    textile = markup_styles(:textile)
    ss = SystemSettings.create(:default_markup_style_id => textile.id)
    assert_equal(textile, ss.default_markup_style)
  end


  def test_default_markup_style_raises_when_style_not_found
    ss = SystemSettings.create(:default_markup_style_id => 0)
    assert_raise(ActiveRecord::RecordNotFound) {ss.default_markup_style}
  end


  def test_default_markup_style_returns_none_when_id_is_nil
    ss = SystemSettings.create(:default_markup_style_id => nil)
    style = ss.default_markup_style
    assert_nil(style.id)
    assert_equal('(None)', style.name)
  end


  def test_site_default_page
    page = content_pages(:site_default_page)
    ss = SystemSettings.create(:site_default_page_id => page.id)
  end


  def test_site_default_page_raises_when_page_not_found
    ss = SystemSettings.create
    assert_raise(ActiveRecord::RecordNotFound) {ss.site_default_page}
  end


  def test_not_found_page
    page = content_pages(:not_found_page)
    ss = SystemSettings.create(:not_found_page_id => page.id)
  end


  def test_not_found_page_raises_when_page_not_found
    ss = SystemSettings.create
    assert_raise(ActiveRecord::RecordNotFound) {ss.not_found_page}
  end


  def test_permission_denied_page
    page = content_pages(:permission_denied_page)
    ss = SystemSettings.create(:permission_denied_page_id => page.id)
  end


  def test_permission_denied_page_raises_when_page_permission_denied
    ss = SystemSettings.create
    assert_raise(ActiveRecord::RecordNotFound) {ss.permission_denied_page}
  end


  def test_session_expired_page
    page = content_pages(:session_expired_page)
    ss = SystemSettings.create(:session_expired_page_id => page.id)
  end


  def test_session_expired_page_raises_when_page_session_expired
    ss = SystemSettings.create
    assert_raise(ActiveRecord::RecordNotFound) {ss.session_expired_page}
  end


  def test_system_pages_returns_nil_when_tested_page_not_system_page
    ss = SystemSettings.create
    page = content_pages(:site_default_page)
    assert_nil(ss.system_pages(page.id))
  end

  def test_system_pages_returns_array_of_apropos_strings_when_tested_page_system_page
    default_page_string = 'Site default page'
    default_page_string.freeze
    not_found_page_string = 'Not found page'
    not_found_page_string.freeze
    permission_denied_page_string = 'Permission denied page'
    permission_denied_page_string.freeze
    session_expired_page_string = 'Session expired page'
    session_expired_page_string.freeze

    ss = SystemSettings.create
    page = content_pages(:site_default_page)
    assert_nil(ss.system_pages(page.id))

    ss.site_default_page_id = page.id
    assert(ss.save)
    arr = ss.system_pages(page.id)
    assert(arr.kind_of?(Array))
    assert(arr.length == 1)
    assert(arr.include?(default_page_string))

    ss.not_found_page_id = page.id
    assert(ss.save)
    arr = ss.system_pages(page.id)
    assert(arr.kind_of?(Array))
    assert(arr.length == 2)
    assert(arr.include?(not_found_page_string))
    assert(arr.include?(default_page_string))

    ss.permission_denied_page_id = page.id
    assert(ss.save)
    arr = ss.system_pages(page.id)
    assert(arr.kind_of?(Array))
    assert(arr.length == 3)
    assert(arr.include?(permission_denied_page_string))
    assert(arr.include?(not_found_page_string))
    assert(arr.include?(default_page_string))

    ss.session_expired_page_id = page.id
    assert(ss.save)
    arr = ss.system_pages(page.id)
    assert(arr.kind_of?(Array))
    assert(arr.length == 4)
    assert(arr.include?(session_expired_page_string))
    assert(arr.include?(permission_denied_page_string))
    assert(arr.include?(not_found_page_string))
    assert(arr.include?(default_page_string))
  end

end
