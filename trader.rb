
class Trader

  attr_reader :api_info
  attr_accessor :time

  def initialize(time=nil)
    # api info hash
    # key, secret, host (base url), data_port, order_port
    @interface ||= Interface.new(@api_info)
    @time = time
    # Asks for time we should leave bot running
    if time
      Thread.new{
        Timeout::timeout(time) {
          #execute trading strategy
        }
      }
    else

    end
  end

  def update_price
    price = @interface.get_price

    @bid = price['bid']
    @ask = price['ask']
  end

end