require 'redis'

class Trader
  include Interface
  attr_reader :api_info
  attr_accessor :time

  def initialize(time=nil)
    $data = Redis.new

    @order_book ||= OrderBook.new
    @order_book.last_day_price = Interface.get_last_day_price
    @time = time
    # Asks for time we should leave bot running
    if time
      Thread.new{
        Timeout::timeout(time) {
          # execute trading strategy
          # want to include parameters for money willing to spend
          # need an order book to store time of quotes
          # calculate a weighted moving average of prices
          # make a buy when price dips below moving average
        }
      }
    else

    end
  end

  def update_price
    price = Interface.get_price

    @bid = price['bid']
    @ask = price['ask']
  end

end