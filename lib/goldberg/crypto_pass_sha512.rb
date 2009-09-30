require "digest/sha2"

module Goldberg
  module CryptoPassSha512
    class << self
      attr_accessor :join_token
      
      # barrowed from authlogic module
      # The number of times to loop through the encryption.
      def stretches
        @stretches ||= 20
      end
      attr_writer :stretches

      # Turns your raw password into a Sha512 hash.
      def encrypt(*tokens)
        digest = tokens.flatten.join(join_token)
        stretches.times { digest = Digest::SHA512.hexdigest(digest) }
        digest
      end

      # checks password for a match
      def matches?(crypted, *tokens)
        encrypt(*tokens) == crypted
      end
    end
  end
end