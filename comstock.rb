require 'trader'
require 'order_book'

Trader.new(100, {:buy_limit => 200, :sell_limit => 200})