
module Bter
  class Trade
  
    attr_accessor :key, :secret
        
    def trade_request(method, params=nil)
      if params.nil?
        @params = {:method => method}
      else
        @params = {:method => method}
        params.each do |param|
          @params.merge!(param)
        end
      end
      request = Typhoeus::Request.new(
        "https://bter.com/api/1/private/#{method}",
        method: :post,
        body: @params,
        headers: { Key: @key, Sign: sign }
        )
        Request_logger.new.error_log(request)
        hydra = Typhoeus::Hydra.hydra
        hydra.queue(request)
        hydra.run
        response = request.response
        Request_logger.new.info_log(response.code, response.total_time, response.headers_hash)
        response.body
    end
    
    def sign
      hmac = OpenSSL::HMAC.new(@secret,OpenSSL::Digest::SHA512.new)
      @params = @params.collect {|k,v| "#{k}=#{v}"}.join('&')
      signed = hmac.update @params      
    end
       
    def get_info    
      query = trade_request "getfunds"
      info = JSON.parse query, {:symbolize_names => true}    
    end
    
    def active_orders
      query = trade_request "orderlist"
      info = JSON.parse query, {:symbolize_names => true}
    end 
    
    def trade(*params)
      query = trade_request "placeorder", params
      info = JSON.parse query, {:symbolize_names => true}
    end
    
    #abstract the trade to buy and sell
    def buy(pair, amount)
      pair_rate = get_rate(pair)
      trade({:pair => pair, :type => "BUY", :rate => pair_rate, :amount => amount})
    end
    
    def sell(pair, amount)
      pair_rate = get_rate(pair)
      trade({:pair => pair, :type => "SELL", :rate => pair_rate, :amount => amount})
    end
    
    def order_status(order_id)
      query = trade_request "getorder", [{:id => order_id}]
      info = JSON.parse query, {:symbolize_names => true}
    end
    
    def cancel_order(order_id)
      query = trade_request "cancelorder", [{:id => order_id}]
      info = JSON.parse query, {:symbolize_names => true}
    end
    
    def get_rate(pair)
      ticker(pair).values_at(:last).flatten
    end
    
  end
end
     
