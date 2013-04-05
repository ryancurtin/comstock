class OrderBook
  include Interface
  attr_accessor :spent, :orders

  # Need a simple way to export Redis data to a database
  def initialize
    @orders = []
    @spent = 0
  end

  # TODO:  Move data gathering out of order book
  # TODO:  Merge hourly data from past data in cache to form new dataset
  def current_hourly_data
    base_time   = Time.now 
    cutoff_time = base_time - 1.hour
    $data.sadd('hourly_data_keys', base_time.to_i)
    $logger.info "Getting last hour of data starting at: #{base_time}, cached under key #{base_time.to_i}"

    # Getting the last 100 trades, checking if there is
    # at least one hour of trade data
    trade_data = Interface.get_last_100_trades
    last_trade_time = Time.at(trade_data.last['timestamp'])
    last_trade_seq = trade_data.last['seq']

    # Adding first batch of data to cache
    add_data_to_cache(trade_data, base_time, cutoff_time)

    # Continuing to add data to the cache to get an hour worth of trades
    while last_trade_time < cutoff_time
      $logger.info "Fetching additional trade data..."
      trade_data = Interface.get_last_100_trades(last_trade_seq)
      last_trade_time = Time.at(trade_data.last['timestamp'])
      last_trade_seq = trade_data.last['seq']
      add_data_to_cache(trade_data, base_time, cutoff_time)
    end

  end

  def add_data_to_cache(trade_data, base_time, cutoff_time)
    trade_data.each do |trade|
      time = Time.at(trade['timestamp'])
      $data.sadd(base_time.to_i, trade.to_json) if (time.to_i > cutoff_time.to_i && time.to_i < base_time.to_i)
    end
  end

  def hourly_moving_average
    hourly_data = current_hourly_data
    average = hourly_data.map{ |point| point['price'].to_i }.inject{|sum, price| sum + price}.to_f / hourly_data.length
  end

  def process_order(order_data, price, trade_size, type)
    @orders << {:timestamp => order_data['timestamp'], :order_id => order_data['order_id']}
    @spent += price * trade_size if type == 0
  end

end