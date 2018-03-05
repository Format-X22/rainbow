require 'colorize'

module Polymorph class Logger
	attr_writer :tick

	def initialize(opt)
		@opt = opt
	end

	def start(date)
		puts "Start\t#{date_val(date)}".bold
	end

	def buy
		puts "Buy\t#{date_val}" unless @opt.off_order_log
	end

	def buy_profit
		puts "Close\t#{date_val}".cyan unless @opt.off_profit_log
	end

	def buy_fail
		puts "Close\t#{date_val}".yellow unless @opt.off_fail_log
	end

	def sell
		puts "Sell\t#{date_val}" unless @opt.off_order_log
	end

	def sell_profit
		puts "Close\t#{date_val}".cyan unless @opt.off_profit_log
	end

	def sell_fail
		puts "Close\t#{date_val}".yellow unless @opt.off_fail_log
	end

	def result(prefix, data)
		puts "RESULT\t#{prefix}\t#{data.round(2)}".bold
	end

	def date
		puts date_val
	end

	def empty
		puts "\n"
	end

	private

	def date_val(date = @tick.date)
		Time.at(date).to_s.split(' ')[0..-2].join(' ').split(':')[0..-2].join(':')
	end

end end