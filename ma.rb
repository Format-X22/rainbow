require 'date'
require 'moving_average'

class MoveAverage

	SHORT_MA_PERIOD = 100
	LONG_MA_PERIOD = 50
	SKIP = [SHORT_MA_PERIOD, LONG_MA_PERIOD].max + 1
	TAKE = 0.003
	SAFE = 0.002 + TAKE
	MARGIN = 0.01
	PROFIT = 0.15
	BREAK_FILTER = 1.0025
	LARGE_CANDLE = 1.02

	def initialize
		@data = Marshal.restore(File.read('data.txt')).last(288 * 7)
		@logger = Logger.new
		@ma_state = MaState.new @data, LONG_MA_PERIOD, SHORT_MA_PERIOD

		@result = 0
		@state = 'wait'
		@order = nil

		calc
	end

	def calc
		@data.each.with_index do |tick_data, index|
			next if do_skip_procedure(tick_data, index)

			@tick = Tick.new tick_data
			@last = Tick.new @last_data

			@logger.tick = @tick

			@ma_state.calc_ma(index)

			case @state
				when 'wait' then handle_wait
				when 'long' then handle_long
				when 'short' then handle_short
			end

			@ma_state.swap_l
			@last_data = tick_data
		end

		@logger.result(@result)
	end

	def do_skip_procedure(data, index)
		if index < SKIP
			@last_data = data

			if index == SKIP - 1
				@ma_state.calc_l_ma(index)
				@logger.start(data.first)
			end

			true
		else
			false
		end
	end

	def handle_wait
		if @ma_state.long > @ma_state.short
			if filters [
				cross_long_ma,
				break_filter(@ma_state.long),
				large_candle_filter,
				fast_reverse_filter,
				serial_fast_reverse_filter,
				cross_near_filter,
				all_ma_break_filter
			]
				@state = 'long'
			end
		else
			if filters [
				cross_short_ma,
				break_filter(@ma_state.short),
				large_candle_filter,
				fast_reverse_filter,
				serial_fast_reverse_filter,
				cross_near_filter,
				all_ma_break_filter
			]
				@state = 'short'
			end
		end
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

	def cross_long_ma
		@tick.high > @ma_state.long and @tick.low < @ma_state.long and @last.high < @ma_state.l_long
	end

	def cross_short_ma
		@tick.high > @ma_state.short and @tick.low < @ma_state.short and @last.low > @ma_state.l_short
	end

	def break_filter(ma)
		@tick.low * BREAK_FILTER < ma
	end

	def large_candle_filter
		@tick.high / @tick.low < LARGE_CANDLE
	end

	def fast_reverse_filter
		true
	end

	def serial_fast_reverse_filter
		true
	end

	def cross_near_filter
		true
	end

	def all_ma_break_filter
		true
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
		attr_reader :short, :long, :l_short, :l_long

		def initialize(data, long_period, short_period)
			@data = data.map{|v| v[2]}
			@long_period = long_period
			@short_period = short_period
		end

		def calc_ma(index)
			@long = @data.sma(index, @long_period)
			@short = @data.sma(index, @short_period)
		end

		def calc_l_ma(index)
			@l_long = @data.sma(index, @long_period)
			@l_short = @data.sma(index, @short_period)
		end

		def swap_l
			@l_long = @long
			@l_short = @short
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

MoveAverage.new