module Goldberg

  class << self

    # Accessor to attach the current user (if logged in)
    attr_accessor :user

    # Accessor to attach the session's credentials
    attr_accessor :credentials

    # Accessor to attach the session's menu
    attr_accessor :menu
    
    # return nil if there is no user
    def user
      begin @user rescue nil end
    end

    # Return Goldberg's System Settings
    def settings
      @settings ||= Goldberg::SystemSettings.find(:first)
    end

    def clear!
      @user = nil
      @credentials = nil
      @menu = nil
      @settings = nil
    end

  end
  
end
