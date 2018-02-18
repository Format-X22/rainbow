require 'moving_average'

class Rainbow

	VIOLET = 10
	BLUE = 25
	GREEN = 50
	RED = 100
	BLACK = 300

	def initialize
		@data = Marshal.restore(File.read('data.txt')).last(288 * 7)
		@logger = Logger.new
		@ma_state = MaState.new @data, VIOLET, BLUE, GREEN, RED, BLACK

		@result = 0
		@state = 'wait'
		@order = nil

		calc

		@logger.result(@result)
	end

	def calc
		@data.each.with_index do |tick_data, index|
			next if do_skip_procedure(tick_data, index)

			@index = index
			@tick = Tick.new tick_data

			@logger.tick = @tick

			@ma_state.calc_ma(@index)

			# trackers

			case @state
				# state machine
			end
		end

		@logger.result(@result)
	end

	def do_skip_procedure(data, index)
		if index < BLACK + 1
			if index == BLACK
				@logger.start(data.first)
			end

			true
		else
			false
		end
	end

	def filters(items)
		items.all? {|i| i}
	end

	class Tick
		attr_reader :date, :open, :close, :high, :low

		def initialize(data)
			@date, @open, @close, @high, @low = data
		end
	end

	class MaState
		attr_reader :violet, :blue, :green, :red, :black

		def initialize(data, *periods)
			@data = data.map{|v| v[2]}
			@periods = periods
		end

		def calc_ma(index)
			@violet = @data.sma(index, @periods[0])
			@blue = @data.sma(index, @periods[1])
			@green = @data.sma(index, @periods[2])
			@red = @data.sma(index, @periods[3])
			@black = @data.sma(index, @periods[4])
		end
	end

	class Logger
		attr_writer :tick

		def start(date)
			puts "Start :: #{Time.at date}"
		end

		def buy
			puts "Buy at :: #{Time.at @tick.date}"
		end

		def buy_profit
			puts "Buy PROFIT :: #{Time.at @tick.date}"
		end

		def buy_fail
			puts "Buy FAIL :: #{Time.at @tick.date}"
		end

		def sell
			puts "Sell at :: #{Time.at @tick.date}"
		end

		def sell_profit
			puts "Sell PROFIT :: #{Time.at @tick.date}"
		end

		def sell_fail
			puts "Sell FAIL :: #{Time.at @tick.date}"
		end

		def result(data)
			puts "RESULT #{data.round(2)}"
		end

	end
end

Rainbow.new