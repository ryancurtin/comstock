require 'redis'
require 'logger'

class Trader
  include Interface
  attr_reader :api_info
  attr_accessor :time

  def initialize(time=nil, opttions={})
    $data = Redis.new
    $logger = Logger.new('comstock')

    # Getting initial account balances and setting paramaters for trader
    # May look to stop execution if defaults are not provided
    account_info  = Interface.get_account_info
    usd_amount    = account_info.select{|acct| acct['currency'] == 'USD'}.first['amount']
    btc_amount    = account_info.select{|acct| acct['currency'] == 'BTC'}.first['amount']
    buy_limit     = options[:buy_limit].to_f || usd_amount.to_f / 10
    sell_limit    = options[:sell_limit].to_f || btc_amount.to_f / 10
    trade_size    = options[:trade_size].to_f || usd_amount.to_f / 100

    @order_book ||= OrderBook.new
    @order_book.last_day_price = Interface.get_last_day_price

    # Asks for time we should leave bot running
    if time
      Thread.new{
        Timeout::timeout(time) {
          # execute trading strategy
          # want to include parameters for money willing to spend
          # need an order book to store time of quotes
          # calculate a weighted moving average of prices
          # make a buy when price dips below moving average
          @stop_selling = false
          @stop_buying = false

          while true
            update_price
            @stop_buying = true if (@order_book.spent + @ask*trade_size) >= buy_limit
            @stop_selling = true if (@order_book.spent + @bid*trade_size) >= sell_limit

            hourly_moving_average = @order_book.hourly_moving_average.to_f
            if (@ask - hourly_moving_average) / hourly_moving_average < -0.01 && @stop_buying != true
              $logger.info "Purchasing #{trade_size} BTC at $#{@ask}/BTC, for a total of #{trade_size.to_f * @ask}"
              @order_book.process_order(Interface.buy_bitcoins(@ask, trade_size), @ask, trade_size, 0)
            elsif (@bid - hourly_moving_average).to_f / hourly_moving_average.to_f > 0.01 && @stop_selling != true
              $logger.info "Selling #{trade_size} BTC at $#{@bid}/BTC, for a total of #{trade_size.to_f * @bid}"
              @order_book.process_order(Interface.sell_bitcoins(@bid, trade_size), @bid, trade_size, 1)
            end

            # Re-runs every minute
            sleep 60
          end
        }
      }
    else

    end
  end

  def update_price
    price = Interface.get_price

    @bid = price['bid'][0].to_f
    @ask = price['ask'][0].to_f

    return price
  end

end