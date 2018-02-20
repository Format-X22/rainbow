require 'date'
require 'moving_average'

class MoveAverage

	SHORT_MA_PERIOD = 100
	LONG_MA_PERIOD = 50
	SKIP = [SHORT_MA_PERIOD, LONG_MA_PERIOD].max + 1
	TAKE = 0.004
	SAFE = 0.003 + TAKE
	MARGIN = 0.05
	PROFIT = 0.06
	BREAK_FILTER = 0.0026
	LARGE_CANDLE = 1.014
	SKIP_CROSS = 6
	SKIP_FAST = 0
	SKIP_ALL_MA = 6

	def initialize
		@data = Marshal.restore(File.read('data.txt'))#.last(288 * 7)
		@logger = Logger.new
		@ma_state = MaState.new @data, LONG_MA_PERIOD, SHORT_MA_PERIOD

		@cross_tracker = 0
		@break_short_tracker = 0
		@break_long_tracker = 0

		@result = 0
		@state = 'wait'
		@order = nil

		calc
	end

	def calc
		@data.each.with_index do |tick_data, index|
			next if do_skip_procedure(tick_data, index)

			@index = index
			@tick = Tick.new tick_data
			@last = Tick.new @last_data

			@logger.tick = @tick

			@ma_state.calc_ma(@index)

			break_ma_tracker
			cross_ma_tracker

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
				break_long_ma,
				break_filter(true, @ma_state.long),
				large_candle_filter,
				fast_reverse_filter(true),
				cross_near_filter,
				all_ma_break_filter(true)
			]
				@state = 'long'
			end
		else
			if filters [
				break_short_ma,
				break_filter(false, @ma_state.short),
				large_candle_filter,
				fast_reverse_filter(false),
				cross_near_filter,
				all_ma_break_filter(false)
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

	def break_ma_tracker
		if @last.high * (1 + BREAK_FILTER) > @ma_state.long and @last.low * (1 - BREAK_FILTER) < @ma_state.long
			@break_long_tracker = @index
		end

		if @last.high * (1 + BREAK_FILTER) > @ma_state.short and @last.low * (1 - BREAK_FILTER) < @ma_state.short
			@break_short_tracker = @index
		end
	end

	def cross_ma_tracker
		ma = @ma_state

		if (ma.l_long > ma.l_short and ma.long <= ma.short) or (ma.l_long < ma.l_short and ma.long >= ma.short)
			@cross_tracker = @index
		end
	end

	def break_long_ma
		@tick.high > @ma_state.long and @tick.low < @ma_state.long and @last.high < @ma_state.l_long
	end

	def break_short_ma
		@tick.high > @ma_state.short and @tick.low < @ma_state.short and @last.low > @ma_state.l_short
	end

	def break_filter(from_down, ma)
		if from_down
			@tick.high * (1 - BREAK_FILTER) > ma
		else
			@tick.low * (1 + BREAK_FILTER) < ma
		end
	end

	def large_candle_filter
		@tick.high / @tick.low < LARGE_CANDLE
	end

	def fast_reverse_filter(long)
		if long
			@break_long_tracker + SKIP_FAST <= @index
		else
			@break_short_tracker + SKIP_FAST <= @index
		end
	end

	def cross_near_filter
		@cross_tracker + SKIP_CROSS < @index
	end

	def all_ma_break_filter(long)
		if long
			@break_short_tracker + SKIP_ALL_MA < @index and @tick.low > @ma_state.short
		else
			@break_long_tracker + SKIP_ALL_MA < @index and @tick.high < @ma_state.long
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