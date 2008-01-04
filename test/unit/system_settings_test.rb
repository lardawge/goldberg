require File.dirname(__FILE__) + '/../test_helper'

class SystemSettingsTest < Test::Unit::TestCase
  include Goldberg::TestHelper

  def test_public_role
    public_role = Goldberg::Role.find :first
    ss = Goldberg::SystemSettings.create(:public_role_id => public_role.id)
    assert_equal(public_role, ss.public_role)
  end

  def test_public_role_raises_when_role_not_found
    ss = Goldberg::SystemSettings.create
    assert_raise(ActiveRecord::RecordNotFound) {ss.public_role}
  end

  def test_site_default_page
    page = Goldberg::ContentPage.find :first
    ss = Goldberg::SystemSettings.create(:site_default_page_id => page.id)
  end


  def test_site_default_page_raises_when_page_not_found
    ss = Goldberg::SystemSettings.create
    assert_raise(ActiveRecord::RecordNotFound) {ss.site_default_page}
  end


  def test_not_found_page
    page = Goldberg::ContentPage.find :first
    ss = Goldberg::SystemSettings.create(:not_found_page_id => page.id)
  end


  def test_not_found_page_raises_when_page_not_found
    ss = Goldberg::SystemSettings.create
    assert_raise(ActiveRecord::RecordNotFound) {ss.not_found_page}
  end


  def test_permission_denied_page
    page = Goldberg::ContentPage.find :first
    ss = Goldberg::SystemSettings.create(:permission_denied_page_id => page.id)
  end


  def test_permission_denied_page_raises_when_page_permission_denied
    ss = Goldberg::SystemSettings.create
    assert_raise(ActiveRecord::RecordNotFound) {ss.permission_denied_page}
  end


  def test_session_expired_page
    page = Goldberg::ContentPage.find :first
    ss = Goldberg::SystemSettings.create(:session_expired_page_id => page.id)
  end


  def test_session_expired_page_raises_when_page_session_expired
    ss = Goldberg::SystemSettings.create
    assert_raise(ActiveRecord::RecordNotFound) {ss.session_expired_page}
  end


  def test_system_pages_returns_nil_when_tested_page_not_system_page
    ss = Goldberg::SystemSettings.create
    page = Goldberg::ContentPage.find :first
    assert_nil(ss.system_pages(page.id))
  end

end
