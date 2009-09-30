require 'active_support/secure_random'

module Goldberg
  class User < ActiveRecord::Base
    include Goldberg::Model

    belongs_to :role, :class_name => 'Goldberg::Role'
    
    validates_presence_of :name, :role_id, :password
    validates_uniqueness_of :name
    
    attr_accessor :clear_password
    attr_accessor :confirm_password

    def before_validation
      if self.clear_password  # Only update password if changed
        self.password_salt = self.object_id.to_s + rand.to_s
        self.password = Goldberg::CryptoPassSha512.encrypt(self.password_salt +
                                                  self.clear_password)
      end
    end
      
    def before_save
      if self.self_reg_confirmation_required
        self.set_confirmation_key
      end
    end
    
    def after_save
      self.clear_password = nil
    end
    
    def check_password(clear_password)
      token = self.password_salt.to_s + clear_password
      if Goldberg::CryptoPassSha512.matches?(self.password, token)
        return true
      elsif Goldberg::CryptoPassSha1.matches?(self.password, token)
        self.password = Goldberg::CryptoPassSha512.encrypt(token)
        self.save
        return true
      else
        return false
      end
    end

    def set_confirmation_key
      self.confirmation_key = SecureRandom.hex(24)
    end

    def email_valid?
      self.email &&
        self.email.length > 0 &&
        # http://regexlib.com/DisplayPatterns.aspx
        self.email =~ /\A[A-Z0-9_\.%\+\-]+@(?:[A-Z0-9\-]+\.)+(?:[A-Z]{2,4}|museum|travel)\z/i
    end

    def get_start_path
      if self.start_path and self.start_path.length > 0
        self.start_path
      else
        self.role.get_start_path
      end
    end

    class << self
      def random_password
        letters = ('A' .. 'Z').to_a + ('a' .. 'z').to_a
        password = (1 .. 6).collect do
          letters[ (rand * letters.length).to_i ]
        end
        password.to_s
      end
    end  # class methods
    
  end
end
