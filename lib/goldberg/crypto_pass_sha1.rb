require "digest/sha1"

module Goldberg
  module CryptoPassSha1
    class << self
      def matches?(password, token)
        Digest::SHA1.hexdigest(token) == password
      end
    end
  end
end