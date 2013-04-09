require 'httparty'
require 'base64'
require 'openssl'
require 'json'
require 'querystring'

module Interface
  attr_reader :header_info

  @header_info = JSON.parse(File.read("keys.json"))

  API_URLS = {
    :get_price => "#{@header_info['host']}/book/L1/1",
    :get_last_day_price => "#{@header_info['host']}/day-info/1",
    :get_last_100_trades => "#{@header_info['host']}/trades/1",
    :get_account_info => "#{@header_info['host']}/accounts",
    :buy_bitcoins => "#{@header_info['host']}/order/new",
    :sell_bitcoins => "#{@header_info['host']}/order/new",
    :check_order_status => "#{@header_info['host']}/order/details",
    :check_open_orders => "#{@header_info['host']}/orders",
    :check_account_info => "#{@header_info['host']}/accounts"
  }

  def self.get_price
    HTTParty.get(API_URLS[:get_price]).parsed_response
  end

  def self.get_last_day_price
    HTTParty.get(API_URLS[:get_last_day_price]).parsed_response
  end

  def self.get_last_100_trades(seq=nil)
    if seq
      HTTParty.get(API_URLS[:get_last_100_trades], :body => {:seq => seq}).parsed_response
    else
      HTTParty.get(API_URLS[:get_last_100_trades]).parsed_response
    end
  end

  def self.get_account_info
    post_request(API_URLS[:get_account_info]).parsed_response
  end

  def self.usd_available
    get_account_info.select{|acct| acct['currency'] == 'USD'}.first['amount']
  end

  def self.btc_available
    get_account_info.select{|acct| acct['currency'] == 'BTC'}.first['amount']
  end

  def self.buy_bitcoins(price, size)
    payload = {product_id: 1, size: size, price: price, side: 0}
    post_request(API_URLS[:buy_bitcoins], payload)
  end

  def self.sell_bitcoins(price, size)
    payload = {product_id: 1, size: size, price: price, side: 1}
    post_request(API_URLS[:sell_bitcoins], payload)
  end

  def self.check_order_status(order_id)
    payload = {:order_id => order_id}
    post_request(API_URLS[:check_order_status], payload)
  end

  def self.check_open_orders
    post_request(API_URLS[:check_open_orders])
  end

  def self.check_account_info
    post_request(API_URLS[:check_account_info])
  end

  def self.build_headers(payload)
    # Signing the request, per the API: http://bitfloor.com/docs/ai/order-entry/rest
    # The sign field is a sha512-hmac of the request body using the secret key which corresponds to your api key
    # To sign your request: base64 decode the secret key into the raw bytes (64 bytes)
    # Use those bytes for your sha512-hmac signing of the http request body
    # Base64 encode the signing result and send in this header field

    secret_key = Base64.strict_decode64(@header_info['secret'])
    hmac = OpenSSL::HMAC.new(secret_key, OpenSSL::Digest::Digest.new('SHA512'))
    sign = Base64.strict_encode64(hmac.update(payload).digest)

    headers = {}
    headers['Content-Type'] = 'application/x-www-form-urlencoded'
    headers['bitfloor-key'] = @header_info['key']
    headers['bitfloor-sign'] = sign
    headers['bitfloor-passphrase'] = @header_info['passphrase']
    headers['bitfloor-version'] = "1"

    return headers
  end

  private
    
    def self.post_request(url, payload={})
      payload.merge!('nonce' => Time.now.to_i)
      headers = build_headers(::QueryString.stringify(payload))
      HTTParty.post(url, { :body => payload, :headers => headers } )
    end

end