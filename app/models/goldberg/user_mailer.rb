module Goldberg
  class UserMailer < ActionMailer::Base
    self.template_root = File.join("#{File.dirname(__FILE__)}/../../../app/views")
    
    def confirmation_request(user, sent_at = Time.now)
      @subject    = 'Registration confirmation required'
      @body       = { :name => user.fullname, :key => user.confirmation_key, :url_str =>
        "#{Goldberg.settings.site_url_prefix}" +
        "goldberg/users/confirm_registration/" +
        "#{user.confirmation_key}" }
      @recipients = user.email
      @from       = ''
      @sent_on    = sent_at
      @content_type = 'text/html'
      @headers    = {}
    end

    def reset_password_request(user, sent_at = Time.now)
      @subject    = 'Reset password'
      @body       =  { :name => user.fullname, :key => user.confirmation_key, :url_str =>
        "#{Goldberg.settings.site_url_prefix}" +
        "goldberg/users/reset_password/" +
        "#{user.confirmation_key}" }
      @recipients = user.email
      @from       = ''
      @sent_on    = sent_at
      @content_type = 'text/html'
      @headers    = {}
    end

    def reset_password(user, password, sent_at = Time.now)
      @subject    = 'Password changed'
      @body       =  { :name => user.fullname, :password => password }
      @recipients = user.email
      @from       = ''
      @sent_on    = sent_at
      @content_type = 'text/html'
      @headers    = {}
    end


  end
end
