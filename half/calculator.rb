require_relative 'options'
require_relative 'tick'
require_relative 'ma_state'
require_relative 'logger'

class Half

	def initialize(options)
		@opt = Options.new(options)
		@data = Marshal.restore(File.read(@opt.source))

		if @opt.last
			@data = @data.last(@opt.last)
		end

		@logger = Logger.new(@opt)
		@ma_state = MaState.new @data, @opt.green, @opt.red, @opt.blue

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
		if index < @opt.blue + 1
			@cross_track = index

			if index == @opt.blue
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

		if @order * (1 - @opt.margin) > @tick.low
			unless @opt.off_fail
				@result -= 1
				@cum_result = 0
				@cum_half_result = 0
			end

			@order = nil
			@state = 'wait'

			@logger.buy_fail
		elsif @order * (1 + @opt.take) < @tick.high
			unless @opt.off_profit
				@result += @opt.profit
				@cum_result = @cum_result * (1 + @opt.profit)
				@cum_half_result = @cum_half_result * (1 + (@opt.profit / 2))
			end

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

		if @order * (1 + @opt.margin) < @tick.high
			unless @opt.off_fail
				@result -= 1
				@cum_result = 0
			end

			@order = nil
			@state = 'wait'

			@logger.sell_fail
		elsif @order * (1 - @opt.take) > @tick.low
			unless @opt.off_profit
				@result += @opt.profit
				@cum_result = @cum_result * (1 + @opt.profit)
				@cum_half_result = @cum_half_result * (1 + (@opt.profit / 2))
			end

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

		if @move_track_store.size == @opt.move_window
			min = @move_track_store.map{|v| v[1].to_f}.min
			max = @move_track_store.map{|v| v[0].to_f}.max

			@move_track = max / min
			@move_track_store.shift
		end
	end

	def flat_tracker
		flat = @flat_track_store

		flat.push [@ma_state.blue, @ma_state.red, @ma_state.green]

		if flat.size == @opt.flat_window


			min_blue, max_blue = extract_flat(flat, 0)
			min_red, max_red = extract_flat(flat, 1)
			min_green, max_green = extract_flat(flat, 2)

			@flat_track = [max_blue / min_blue, max_red / min_red, max_green / min_green]
			flat.shift
		end
	end

	def extract_flat(arr, index)
		flat = arr.map{|v| v[index].to_f}.first(@opt.flat_window - @opt.flat_slice)

		[flat.min, flat.max]
	end

	def blue_cross_filter
		@blue_allow
	end

	def move_filter
		if @move_track

			@move_track < @opt.move_max
		else
			false
		end
	end

	def flat_filter
		if @flat_track
			@flat_track[0] > 1 + @opt.flat_blue and
			@flat_track[1] > 1 + @opt.flat_red and
			@flat_track[2] > 1 + @opt.flat_green
		else
			false
		end
	end

	def cross_filter
		@cross_track > @cross_track_last + @opt.cross_skip
	end

	def filters(items)
		items.all? {|i| i}
	end
end