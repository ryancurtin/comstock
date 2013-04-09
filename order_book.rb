class OrderBook
  include Interface
  attr_accessor :spent, :orders, :data_loaded

  def initialize
    @orders = []
    @spent = 0
  end

  def trade_key(timestamp)
    timestamp.strftime("%-m%-d%k")
  end

  # ------------------- Data Processing / Caching Methods --------------------- #
  # TODO:  Move data gathering out of order book
  # TODO:  Export Redis data to persistent datastore - on-demand moving average from
  #        a larget dataset

  def load_historical_data
    base_time   = Time.now 
    cutoff_time = base_time - 3600
    $logger.info "Getting last hour of data starting at: #{base_time}, cached under key #{base_time.to_i}"

    # Getting the last 100 trades, checking if there is
    # at least one hour of trade data
    trade_data = Interface.get_last_100_trades
    last_trade_time = Time.at(trade_data.last['timestamp'])
    last_trade_seq = trade_data.last['seq']

    # Adding first batch of data to cache
    add_data_to_cache(trade_data)

    # Continuing to add data to the cache if we don't have at least 1 hour of trades
    while last_trade_time < cutoff_time
      $logger.info "Fetching additional trade data..."
      
      # Re-setting the starting point; only relevant if we didn't get at least 1 hour of trades
      trade_data = Interface.get_last_100_trades(last_trade_seq)
      last_trade_time = Time.at(trade_data.last['timestamp'])
      last_trade_seq = trade_data.last['seq']
      
      cache_data(trade_data)
    end

    @data_loaded = true
  end

  def cache_data(trade_data)
    # Adding historical data to Redis
    trade_data.each do |trade|
      time_key = trade_key(Time.at(trade['timestamp']))

      # Storing sequenced keys in a set; hash with trade data retrieved by referencing key
      $data.sadd(time_key, trade['seq'])
      $data.hmset(trade['seq'], 'price', trade['price'], 'timestamp', trade['timestamp'], 'size', trade['size'])
    end
  end

  def get_hourly_data
    # Keys of all trades within the last two hours
    trade_keys = $data.smembers(trade_key(Time.now)) + $data.smembers(trade_key(Time.now - 3600))
    
    # Looping through trades to find only trades from last hour
    trades = []
    trade_keys.each do |k|
      trades << $data.hgetall(k) if k['timestamp'].to_i > cutoff_time.to_i
    end

    trades
  end

  def hourly_moving_average
    load_historical_data unless @data_loaded
    hourly_data = get_hourly_data

    average = hourly_data.map{ |trade| trade['price'].to_i }.inject{|sum, price| sum + price}.to_f / hourly_data.length
  end


  # ------------ Order Storage / Processing ------------------- #
  def process_order(order_data, price, trade_size, type)
    @orders << {:timestamp => order_data['timestamp'], :order_id => order_data['order_id']}
    @spent += price * trade_size if type == 0
  end

end
