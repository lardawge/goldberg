require 'digest/sha1'

module Goldberg
  class UserMailer < ActionMailer::Base
    self.template_root = File.join("#{File.dirname(__FILE__)}/../../../app/views")
    
    def confirmation_request(name,
                             email,
                             key,
                             sent_at = Time.now)
      @subject    = 'Registration confirmation required'
      @body       = { :name => name, :key => key, :url_str =>
        "#{Goldberg.settings.site_url_prefix}" +
        "goldberg/users/confirm_registration/" +
        "#{key}" }
      @recipients = email
      @from       = ''
      @sent_on    = sent_at
      @content_type = 'text/html'
      @headers    = {}
    end

    def reset_password_request(sent_at = Time.now)
      @subject    = 'Reset password'
      @body       = {}
      @recipients = ''
      @from       = ''
      @sent_on    = sent_at
      @headers    = {}
    end
  end
end
