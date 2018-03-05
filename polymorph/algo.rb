require_relative 'logger'
require_relative 'ma'
require_relative 'options'
require_relative 'tick'

module Polymorph class Algo

	def initialize(options)
		@opt = Options.new(options)
		@data = Marshal.restore(File.read(@opt.source))

		if @opt.last
			@data = @data.last(@opt.last)
		end

		@logger = Logger.new(@opt)
		@ma_state = MA.new @data, @opt.green, @opt.red

		@result = 0
		@cum_result = 100
		@cum_half_result = 100
		@state = 'just_wait'
		@order = nil

		calc

		@logger.empty
		@logger.result('simple', @result)
		@logger.result('cum', @cum_result)
		@logger.result('half', @cum_half_result)
	end

	def calc
		@data.each.with_index do |tick_data, index|
			next if do_skip_procedure(tick_data, index)

			@index = index
			@last_tick = @tick
			@tick = Tick.new tick_data
			@logger.tick = @tick

			@ma_state.calc_ma(@index)

			ma_cross_tracker
			price_cross_tracker

			case @state
				when 'just_wait' then handle_just_wait
				when 'fail_wait' then handle_fail_wait
				when 'long_trigger' then handle_long_trigger
				when 'short_trigger' then handle_short_trigger
				when 'long' then handle_long
				when 'short' then handle_short
				when 'fail_long' then handle_fail_long
				when 'fail_short' then handle_fail_short
			end
		end
	end

	def do_skip_procedure(data, index)
		if index < @opt.red + 1
			if index == @opt.red
				@ma_state.calc_ma(index)
				@logger.start(data.first)
				@logger.empty
				@tick = Tick.new data
			end

			true
		else
			false
		end
	end

	def handle_just_wait
		#
	end

	def handle_fail_wait
		#
	end

	def handle_long_trigger
		#
	end

	def handle_short_trigger
		#
	end

	def handle_long
		#
	end

	def handle_short
		#
	end

	def handle_fail_long
		#
	end

	def handle_fail_short
		#
	end

	def ma_cross_tracker
		#
	end

	def price_cross_tracker
		#
	end

	def filters(items)
		items.all? {|i| i}
	end
	
end end