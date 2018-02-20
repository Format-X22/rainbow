require 'moving_average'

class Rainbow

	VIOLET = 10
	BLUE = 25
	GREEN = 50
	RED = 100
	YELLOW = 200
	BLACK = 300

	SAFE = 0.014 + 0.003
	MARGIN = 0.05
	PROFIT = 0.21

	SKIP_CROSS = 20
	SKIP_BLACK_BREAK = 35
	MOVE_WINDOW = 20
	MOVE_MAX = 1.1

	def initialize
		@data = Marshal.restore(File.read('data.txt')).last(288 * 51)
		@logger = Logger.new
		@ma_state = MaState.new @data, VIOLET, BLUE, GREEN, RED, YELLOW, BLACK

		@result = 0
		@cum_result = 100
		@state = 'wait'
		@order = nil

		@cross_track = nil
		@cross_track_last = nil
		@break_track = nil
		@move_track = nil
		@move_track_store = []
		@black_direction = nil
		@black_allow = false

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
			move_tracker
			black_cross_tracker

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
		ma = @ma_state

		if @index == @cross_track
			if ma.violet > ma.blue and ma.blue > ma.green and ma.green > ma.red and ma.red > ma.yellow and ma.yellow > ma.black
				if filters [
					#black_break_filter,
					cross_filter,
					move_filter,
					black_cross_filter
				]
					@state = 'long'
				end

				@black_allow = false
			end

			if ma.violet < ma.blue and ma.blue < ma.green and ma.green < ma.red and ma.red < ma.yellow and ma.yellow < ma.black
				if filters [
					#black_break_filter,
					cross_filter,
					move_filter,
					black_cross_filter
				]
					@state = 'short'
				end

				@black_allow = false
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
			@cum_result = @cum_result / 2
			@order = nil
			@state = 'wait'

			@logger.buy_fail
		elsif @order * (1 + SAFE) < @tick.high
			@result += PROFIT
			@cum_result = @cum_result * (1 + (PROFIT / 2))
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
			@cum_result = @cum_result / 2
			@order = nil
			@state = 'wait'

			@logger.sell_fail
		elsif @order * (1 - SAFE) > @tick.low
			@result += PROFIT
			@cum_result = @cum_result * (1 + (PROFIT / 2))
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

	def move_tracker
		@move_track_store.push [@tick.high, @tick.low]

		if @move_track_store.size == MOVE_WINDOW
			@move_track = @move_track_store.first[0] / @move_track_store.last[1]
			@move_track_store.shift
		end
	end

	def black_cross_tracker
		ma = @ma_state
		last_direction = @black_direction

		if ma.violet > ma.black and ma.blue > ma.black and ma.green > ma.black and ma.red > ma.black
			@black_direction = 'up'
		end

		if ma.violet < ma.black and ma.blue < ma.black and ma.green < ma.black and ma.red < ma.black
			@black_direction = 'down'
		end

		if @black_direction != last_direction
			@black_allow = true
		end
	end

	def black_break_filter
		if @break_track
			@break_track < @index - SKIP_BLACK_BREAK
		else
			false
		end
	end

	def cross_filter
		@cross_track_last < @index - SKIP_CROSS
	end

	def move_filter
		if @move_track

			@move_track < MOVE_MAX
		else
			false
		end
	end

	def black_cross_filter
		@black_allow
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
		attr_reader :violet, :blue, :green, :red, :yellow, :black, :l_green, :l_red

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
			@yellow = @data.sma(index, @periods[4])
			@black = @data.sma(index, @periods[5])
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
			#puts "Buy PROFIT :: #{Time.at @tick.date}"
		end

		def buy_fail
			puts "Buy FAIL :: #{Time.at @tick.date}"
		end

		def sell
			puts "Sell at :: #{Time.at @tick.date}"
		end

		def sell_profit
			#puts "Sell PROFIT :: #{Time.at @tick.date}"
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