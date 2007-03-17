require 'digest/sha1'

module Goldberg
  class User < ActiveRecord::Base
    include GoldbergModel

    validates_presence_of :name
    validates_uniqueness_of :name
    
    attr_accessor :clear_password
    attr_accessor :confirm_password
    
    def role
      if self.role_id
        @role ||= Role.find(self.role_id)
      end
      return @role
    end
    
    def before_save
      if self.clear_password  # Only update the password if it has been changed
        self.password_salt = self.object_id.to_s + rand.to_s
        self.password = Digest::SHA1.hexdigest(self.password_salt +
                                               self.clear_password)
      end
      if self.self_reg_confirmation_required
        self.confirmation_key = Digest::SHA1.hexdigest(self.object_id.to_s +
                                                       rand.to_s)
      end
    end
    
    def after_save
      self.clear_password = nil
    end
    
    def check_password(clear_password)
      self.password == Digest::SHA1.hexdigest(self.password_salt.to_s +
                                              clear_password)
    end
    
  end
end
