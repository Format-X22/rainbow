class Half
	class Logger
		attr_writer :tick

		def initialize(opt)
			@opt = opt
		end

		def start(date)
			puts "Start :: #{Time.at date}"
		end

		def buy
			puts "Buy at :: #{Time.at @tick.date}" unless @opt.off_order_log
		end

		def buy_profit
			puts "Buy PROFIT :: #{Time.at @tick.date}" unless @opt.off_profit_log
		end

		def buy_fail
			puts "Buy FAIL :: #{Time.at @tick.date}" unless @opt.off_fail_log
		end

		def sell
			puts "Sell at :: #{Time.at @tick.date}" unless @opt.off_order_log
		end

		def sell_profit
			puts "Sell PROFIT :: #{Time.at @tick.date}" unless @opt.off_profit_log
		end

		def sell_fail
			puts "Sell FAIL :: #{Time.at @tick.date}" unless @opt.off_fail_log
		end

		def result(data)
			puts "RESULT #{data.round(2)}"
		end

	end
end