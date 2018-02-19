require 'moving_average'

class Rainbow

	VIOLET = 10
	BLUE = 25
	GREEN = 50
	RED = 100
	BLACK = 300

	SAFE = 0.007 + 0.003
	MARGIN = 0.05
	PROFIT = 0.10

	SKIP_CROSS = 20
	SKIP_CROSS_MOVE = 0.02
	SKIP_BLACK_TOUCH = 20

	def initialize
		@data = Marshal.restore(File.read('data.txt')).last(288 * 7)
		@logger = Logger.new
		@ma_state = MaState.new @data, VIOLET, BLUE, GREEN, RED, BLACK

		@result = 0
		@cum_result = 0
		@state = 'wait'
		@order = nil

		@cross_track = nil
		@cross_track_last = nil
		@break_track = nil

		calc

		@logger.result(@result)
		@logger.result(@cum_result)
	end

	def calc
		@data.each.with_index do |tick_data, index|
			next if do_skip_procedure(tick_data, index)

			@index = index
			@tick = Tick.new tick_data
			@logger.tick = @tick

			@ma_state.calc_ma(@index)

			cross_tracker
			break_tracker

			case @state
				when 'wait' then handle_wait
				when 'long' then handle_long
				when 'short' then handle_short
			end
		end
	end

	def do_skip_procedure(data, index)
		if index < BLACK + 1
			@cross_track = index

			if index == BLACK
				@ma_state.calc_ma(index)
				@logger.start(data.first)
			end

			true
		else
			false
		end
	end

	def handle_wait
		#
	end

	def handle_long
		unless @order
			@logger.buy
		end

		@order ||= @tick.open

		if @order * (1 - MARGIN) > @tick.low
			@result -= 1
			@order = nil
			@state = 'wait'

			@logger.buy_fail
		elsif @order * (1 + SAFE) < @tick.high
			@result += PROFIT
			@order = nil
			@state = 'wait'

			@logger.buy_profit
		end
	end

	def handle_short
		unless @order
			@logger.sell
		end

		@order ||= @tick.open

		if @order * (1 + MARGIN) < @tick.high
			@result -= 1
			@order = nil
			@state = 'wait'

			@logger.sell_fail
		elsif @order * (1 - SAFE) > @tick.low
			@result += PROFIT
			@order = nil
			@state = 'wait'

			@logger.sell_profit
		end
	end

	def cross_tracker
		ma = @ma_state

		if (ma.l_red > ma.l_green and ma.red <= ma.green) or (ma.l_red < ma.l_green and ma.red >= ma.green)
			unless @cross_track_last == @index
				@cross_track_last = @cross_track
			end

			@cross_track = @index
		end
	end

	def break_tracker
		if @tick.high > @ma_state.black and @tick.low < @ma_state.black
			@break_track = @index
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
		attr_reader :violet, :blue, :green, :red, :black, :l_green, :l_red

		def initialize(data, *periods)
			@data = data.map{|v| v[2]}
			@periods = periods
		end

		def calc_ma(index)
			@l_green = @green
			@l_red = @red

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