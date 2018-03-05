require 'colorize'

module Polymorph class Logger
	attr_writer :tick

	def initialize(opt)
		@opt = opt
	end

	def start(date)
		puts "Start\t#{date(date)}".bold
	end

	def buy
		puts "Buy\t#{date}" unless @opt.off_order_log
	end

	def buy_profit
		puts "Close\t#{date}".cyan unless @opt.off_profit_log
	end

	def buy_fail
		puts "Close\t#{date}".yellow unless @opt.off_fail_log
	end

	def sell
		puts "Sell\t#{date}" unless @opt.off_order_log
	end

	def sell_profit
		puts "Close\t#{date}".cyan unless @opt.off_profit_log
	end

	def sell_fail
		puts "Close\t#{date}".yellow unless @opt.off_fail_log
	end

	def result(prefix, data)
		puts "RESULT\t#{prefix}\t#{data.round(2)}".bold
	end

	def empty
		puts "\n"
	end

	def date(date = @tick.date)
		Time.at(date).to_s.split(' ')[0..-2].join(' ').split(':')[0..-2].join(':')
	end

end end