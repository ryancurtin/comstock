require 'httparty'
require 'base64'
require 'openssl'

module Interface
  def initialize
    @api_info ||= JSON.parse(File.read('keys.json'))
  end

  def get_price
    self.class.get("https://api.bitfloor.com/book/L1/1").parsed_response
  end

  def buy_bitcoins(price, size)
    url = "https://api.bitfloor.com/order/new"
    payload = {product_id: 1, size: size, price: price, side: 0}
    post_request(url, payload)
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

  def post_request(url, payload={})
    headers = build_headers(payload.merge('nonce' => Time.now.to_i).to_s)
    HTTParty.post(url, { :body => payload, :headers => headers } )
  end

end