require 'openssl'

require 'httparty'

module LedgerBitcoin
  module Bitstamp
    class APIConsumer
      include HTTParty

      def initialize(client_id, api_key, api_secret)
        self.class.base_uri $config[:bitstamp][:api_base_uri]

        @client_id = client_id
        @api_key = api_key
        @api_secret = api_secret        
      end

      def balance
        post_with_signature('/balance/')
      end
      def user_transactions(offset = 0, limit = 100, sort = 'desc')
        post_with_signature('/user_transactions/', body: {:offset => offset, :limit => 100, :sort => sort})
      end

      private

      def post_with_signature(resource, options = {})
        nonce = Time.now.to_i
        signature = signature(nonce)

        options[:body] = {} if options[:body].nil?
        options[:body].merge!({key: @api_key, nonce: nonce.to_s, signature: signature})
        
        self.class.post(resource, options)
      end

      def signature(nonce)
        message = nonce.to_s << @client_id << @api_key

        hex_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new,
                                                @api_secret,
                                                message)

        return hex_signature.upcase
      end      
    end
  end
end
