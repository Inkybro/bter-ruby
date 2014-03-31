module Bter
  module API
    
    HTTP = ::Mechanize.new
    BASE_URI = 'https://bter.com'
    
    class PublicMethod
      def execute_method(method, pair)
        api_method = pair.nil? ? method : "#{method}/#{pair}"
        response = HTTP.get("#{BASE_URI}/api/1/#{api_method}")
        JSON.parse(response.body, { :symbolize_names => true })
      end
    end
    
    class PrivateMethod
      def initialize(key, secret)
        @key = key
        @secret = secret
      end
      
      def execute_method(method, params)
        response = HTTP.post("#{BASE_URI}/api/1/private/#{method}", params, { 
          'Key' => @key, 'Sign' => sign(params) 
        })
        JSON.parse(response.body, { :symbolize_names => true })
      end
      
    private
      def sign(params)
        hmac = OpenSSL::HMAC.new(@secret,OpenSSL::Digest::SHA512.new)
        params = params.collect {|k,v| "#{k}=#{v}"}.join('&')
        signed = hmac.update params      
      end
    end
    
    class Client
      def initialize(key=nil, secret=nil)
        @key = key
        @secret = secret
        @private_caller = nil
      end
      
      ######################
      ### PUBLIC ###########
      ######################
      def pairs
        call_public_api('pairs')
      end
      
      def tickers
        call_public_api('tickers')
      end
      
      def ticker(pair)
        call_public_api('ticker', pair) 
      end
      
      def depth(pair)
        call_public_api('depth', pair)   
      end
      
      def trades(pair)
        call_public_api('trade', pair)   
      end
      
      ######################
      ### PUBLIC ###########
      ######################
      def balances
        call_private_api('getfunds')
      end
      
      def order_list
        call_private_api('orderlist')
      end
      
      def place_order(pair, type, rate, amount)
        call_private_api('placeorder', {
          :pair => pair,
          :type => type,
          :rate => rate,
          :amount => amount
        })
      end
      
      def cancel_order(order_id)
        call_private_api('cancelorder', {
          :order_id => order_id
        })
      end
      
      def get_order(order_id)
        call_private_api('getorder', {
          :order_id => order_id
        })
      end
      
    private
      def call_public_api(method, pair=nil)
        Bter::API::PublicMethod.new.execute_method(method, pair)
      end
      
      def call_private_api(method, params={})
        Bter::API::PrivateMethod.new(@key, @secret).execute_method(method, params)
      end
    end
    
  end
end