require 'digest/sha1'

module Goldberg
  class User < ActiveRecord::Base
    include Goldberg::Model

    belongs_to :role
    
    validates_presence_of :name, :role_id, :password
    validates_uniqueness_of :name
    
    attr_accessor :clear_password
    attr_accessor :confirm_password

    def before_validation
      if self.clear_password  # Only update password if changed
        self.password_salt = self.object_id.to_s + rand.to_s
        self.password = Digest::SHA1.hexdigest(self.password_salt +
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
      self.password == Digest::SHA1.hexdigest(self.password_salt.to_s +
                                              clear_password)
    end

    def set_confirmation_key
      self.confirmation_key = Digest::SHA1.hexdigest(self.object_id.to_s +
                                                       rand.to_s)
    end

    def email_valid?
      self.email &&
        self.email.length > 0 &&
        # http://regexlib.com/DisplayPatterns.aspx
        self.email =~ /\A.+@[^\.].*\.[a-z]{2,}\z/
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
