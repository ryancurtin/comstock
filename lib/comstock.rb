# %x(node market_data.js)

require_relative 'interface'
require_relative 'trader'

account_info  = ::Interface.get_account_info
usd_amount    = account_info.select{|acct| acct['currency'] == 'USD'}.first['amount']
btc_amount    = account_info.select{|acct| acct['currency'] == 'BTC'}.first['amount']

puts "Account information as of #{Time.now.strftime("%-m/%-d/%y : %H:%M:%S")}: "
puts "USD Available: $#{usd_amount.to_f.round(2)}"
puts "BTC Available: #{btc_amount.to_f.round(2)}"

puts "Use defaults? (Enter Y / N) buy limit: 1/10 of the USD in your account, sell_limit: 1/10 of the BTC in your account, individual trade size: 1/100 of the USD in your acccount divided by the market price of BTC"
defaults = gets.chomp.downcase

unless defaults == 'y'

  puts "What do you want the buy limit to be (USD you're willing to spend before the bot shuts down) ? "
  buy_limit = gets.chomp.to_i

  puts "What do you wnat the sell limit to be (value of bitcoins you're willing to sell before the bot shuts down in USD) ? "
  sell_limit = gets.chomp.to_i

  puts "What do you want the trade size to be (size of individual transaction in BTC - take into account available funds listed above) ? "
  trade_size = gets.chomp.to_i

  puts "How long do you want the trader to run for (enter number of seconds - 60 = 1 minute, 3600 = 1 hour"
  time = gets.chomp.to_i

  buy_limit   = nil if buy_limit == 0
  sell_limit  = nil if sell_limit == 0
  trade_size  = nil if trade_size == 0
  time        = nil if time == 0 

end

buy_limit   ||= nil
sell_limit  ||= nil
trade_size  ||= nil
time        ||= nil

Trader.new(time, {:buy_limit => buy_limit, :sell_limit => sell_limit, :trade_size => trade_size, :account_info => account_info})
