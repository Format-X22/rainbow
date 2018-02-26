require 'moving_average'

class Half

	GREEN = 25
	RED = 100
	BLUE = 250

	TAKE = 0.12 + 0.01
	MARGIN = 0.12 # x6.4
	PROFIT = 0.68
	MOVE_WINDOW = 24
	MOVE_MAX = 1.12
	FLAT_SLICE = 4
	FLAT_WINDOW = 24 + FLAT_SLICE
	FLAT_BLUE = 0
	FLAT_RED = 0
	FLAT_GREEN = 0.01
	CROSS_SKIP = 2

	def initialize
		@data = Marshal.restore(File.read('data1h.txt'))#.last(24 * 365)
		@logger = Logger.new
		@ma_state = MaState.new @data, GREEN, RED, BLUE

		@result = 0
		@cum_result = 100
		@cum_half_result = 100
		@state = 'wait'
		@order = nil

		@cross_track = nil
		@cross_track_last = nil
		@blue_direction = nil
		@blue_allow = false
		@move_track = nil
		@move_track_store = []
		@flat_track = nil
		@flat_track_store = []

		calc

		@logger.result(@result)
		@logger.result(@cum_result)
		@logger.result(@cum_half_result)
		@logger.result((@cum_half_result / 100) * 100_000)
	end

	def calc
		@data.each.with_index do |tick_data, index|
			next if do_skip_procedure(tick_data, index)

			@index = index
			@tick = Tick.new tick_data
			@logger.tick = @tick

			@ma_state.calc_ma(@index)

			cross_tracker
			blue_cross_tracker
			move_tracker
			flat_tracker

			case @state
				when 'wait' then handle_wait
				when 'long' then handle_long
				when 'short' then handle_short
			end
		end
	end

	def do_skip_procedure(data, index)
		if index < BLUE + 1
			@cross_track = index

			if index == BLUE
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
			if ma.green > ma.red and ma.red > ma.blue
				if filters [
					blue_cross_filter,
					move_filter,
					flat_filter,
					cross_filter
				]
					@state = 'long'
				end

				@blue_allow = false
			end

			if ma.green < ma.red and ma.red < ma.blue
				if filters [
					blue_cross_filter,
					move_filter,
					flat_filter,
					cross_filter
				]
					@state = 'short'
				end

				@blue_allow = false
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
			@cum_result = 0
			@order = nil
			@state = 'wait'

			@logger.buy_fail
		elsif @order * (1 + TAKE) < @tick.high
			@result += PROFIT
			@cum_result = @cum_result * (1 + PROFIT)
			@cum_half_result = @cum_half_result * (1 + (PROFIT / 2))
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
			@cum_result = 0
			@order = nil
			@state = 'wait'

			@logger.sell_fail
		elsif @order * (1 - TAKE) > @tick.low
			@result += PROFIT
			@cum_result = @cum_result * (1 + PROFIT)
			@cum_half_result = @cum_half_result * (1 + (PROFIT / 2))
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

	def blue_cross_tracker
		ma = @ma_state
		last_direction = @blue_direction

		if ma.green > ma.blue
			@blue_direction = 'up'
		end

		if ma.green < ma.blue
			@blue_direction = 'down'
		end

		if @blue_direction != last_direction
			@blue_allow = true
		end
	end

	def move_tracker
		@move_track_store.push [@tick.high, @tick.low]

		if @move_track_store.size == MOVE_WINDOW
			min = @move_track_store.map{|v| v[1].to_f}.min
			max = @move_track_store.map{|v| v[0].to_f}.max

			@move_track = max / min
			@move_track_store.shift
		end
	end

	def flat_tracker
		flat = @flat_track_store

		flat.push [@ma_state.blue, @ma_state.red, @ma_state.green]

		if flat.size == FLAT_WINDOW


			min_blue, max_blue = extract_flat(flat, 0)
			min_red, max_red = extract_flat(flat, 1)
			min_green, max_green = extract_flat(flat, 2)

			@flat_track = [max_blue / min_blue, max_red / min_red, max_green / min_green]
			flat.shift
		end
	end

	def extract_flat(arr, index)
		flat = arr.map{|v| v[index].to_f}.first(FLAT_WINDOW - FLAT_SLICE)

		[flat.min, flat.max]
	end

	def blue_cross_filter
		@blue_allow
	end

	def move_filter
		if @move_track

			@move_track < MOVE_MAX
		else
			false
		end
	end

	def flat_filter
		if @flat_track
			@flat_track[0] > 1 + FLAT_BLUE and
			@flat_track[1] > 1 + FLAT_RED and
			@flat_track[2] > 1 + FLAT_GREEN
		else
			false
		end
	end

	def cross_filter
		@cross_track > @cross_track_last + CROSS_SKIP
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
		attr_reader :green, :red, :blue, :l_green, :l_red

		def initialize(data, *periods)
			@data = data.map{|v| v[2]}
			@periods = periods
		end

		def calc_ma(index)
			@l_green = @green
			@l_red = @red

			@green = @data.sma(index, @periods[0])
			@red = @data.sma(index, @periods[1])
			@blue = @data.sma(index, @periods[2])
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

Half.new