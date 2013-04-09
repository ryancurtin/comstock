require 'redis'
require 'logger'
require 'timeout'
require_relative 'order_book'

class Trader
  include Interface
  attr_reader :api_info
  attr_accessor :time

  def initialize(time=600, options={})

    $data = Redis.new
    $logger = Logger.new(STDOUT)
    $logger.level = Logger::INFO

    update_price

    # Percentage change required to trigger buy/sell signal
    # Set in Redis so they can be changed dynamically
    $data.set('buy_threshold', -0.01)
    $data.set('sell_threshold', 0.05)

    # Getting initial account balances and setting paramaters for trader
    # May look to stop execution if defaults are not provided
    account_info  = options[:account_info]
    usd_amount    = account_info.select{|acct| acct['currency'] == 'USD'}.first['amount']
    btc_amount    = account_info.select{|acct| acct['currency'] == 'BTC'}.first['amount']
    buy_limit     = options[:buy_limit] || usd_amount.to_f / 10
    sell_limit    = options[:sell_limit] || btc_amount.to_f / 10
    trade_size    = options[:trade_size] || usd_amount.to_f / 100 / @ask

    @order_book ||= OrderBook.new

    # Asks for time we should leave bot running
    Timeout::timeout(time) {
      start_time = Time.now

      # execute trading strategy
      # want to include parameters for money willing to spend
      # need an order book to store time of quotes
      # calculate a weighted moving average of prices
      # make a buy when price dips below moving average
      @stop_selling = false
      @stop_buying = false

      while true
        update_price

        $logger.info "Running for #{((Time.now - start_time) / 60).to_i} minutes..."
        $logger.info "The current price of bitcoin is $#{@ask}"

        @stop_buying = true if (@order_book.spent + @ask*trade_size) >= buy_limit
        @stop_selling = true if (@order_book.spent + @bid*trade_size) >= sell_limit
        break if @stop_buying == true && @stop_selling == true

        hourly_moving_average = @order_book.hourly_moving_average.to_f
        $logger.info "Hourly moving average price of BTC in USD: $#{hourly_moving_average}"

        if (@ask - hourly_moving_average).to_f / hourly_moving_average.to_f < $data.get('buy_threshold').to_f && @stop_buying != true
          $logger.info "Purchasing #{trade_size} BTC at $#{@ask}/BTC, for a total of #{trade_size.to_f * @ask}"
          @order_book.process_order(Interface.buy_bitcoins(@ask, trade_size), @ask, trade_size, 0)
        
        elsif (@bid - hourly_moving_average).to_f / hourly_moving_average.to_f > $data.get('sell_threshold').to_f && @stop_selling != true
          $logger.info "Selling #{trade_size} BTC at $#{@bid}/BTC, for a total of #{trade_size.to_f * @bid}"
          @order_book.process_order(Interface.sell_bitcoins(@bid, trade_size), @bid, trade_size, 1)
        end

        # Re-runs every minute
        sleep 10
      end
    }
  end

  def update_price
    price = Interface.get_price

    @bid = price['bid'][0].to_f
    @ask = price['ask'][0].to_f

    return price
  end

end