require 'httparty'
require 'base64'
require 'openssl'
require 'json'

class Interface
  attr_reader :header_info

  API_URLS = {
    :get_price => "https://api.bitfloor.com/book/L1/1",
    :buy_bitcoins => "https://api.bitfloor.com/order/new",
    :sell_bitcoins => "https://api.bitfloor.com/order/new",
    :check_order_status => "https://api.bitfloor.com/order/details",
    :check_open_orders => "https://api.bitfloor.com/orders",
    :check_account_info => "https://api.bitfloor.com/accounts"
  }

  def initialize
    # @order_book = OrderBook.new
    @header_info ||= JSON.parse(File.read('keys.json'))
  end

  def get_price
    HTTParty.get(API_URLS[:get_price]).parsed_response
  end

  def buy_bitcoins(price, size)
    payload = {product_id: 1, size: size, price: price, side: 0}
    post_request(API_URLS[:buy_bitcoins], payload)
  end

  def sell_bitcoins(price, size)
    payload = {product_id: 1, size: size, price: price, side: 1}
    post_request(API_URLS[:sell_bitcoins], payload)
  end

  def check_order_status(order_id)
    payload = {:order_id => order_id}
    post_request(API_URLS[:check_order_status], payload)
  end

  def check_open_orders
    post_request(API_URLS[:check_open_orders])
  end

  def check_account_info
    post_request(API_URLS[:check_account_info])
  end

  def build_headers(body)
    # Signing the request, per the API: http://bitfloor.com/docs/ai/order-entry/rest
    # The sign field is a sha512-hmac of the request body using the secret key which corresponds to your api key
    # To sign your request: base64 decode the secret key into the raw bytes (64 bytes)
    # Use those bytes for your sha512-hmac signing of the http request body
    # Base64 encode the signing result and send in this header field

    secret_key = Base64.strict_decode64(@api_info['key'])
    hmac = OpenSSL::HMAC.new(secret_key, OpenSSL::Digest::Digest.new('SHA512'))
    sign = Base64.strict_encode64(hmac.update(body).digest)

    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'bitfloor-key' => @api_info['key'],
      'bitfloor-sign' => sign
    }

  end

  private
    
    def post_request(url, payload={})
      headers = build_headers(payload.merge('nonce' => Time.now.to_i).to_s)
      HTTParty.post(url, { :body => payload, :headers => headers } )
    end

end