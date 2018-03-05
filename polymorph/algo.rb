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
		@state = '' # TODO
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
			@tick = Tick.new tick_data
			@logger.tick = @tick

			@ma_state.calc_ma(@index)

			case @state
				when '' then #
			end
		end
	end

	def do_skip_procedure(data, index)
		if index < @opt.red + 1
			if index == @opt.red
				@ma_state.calc_ma(index)
				@logger.start(data.first)
				@logger.empty
			end

			true
		else
			false
		end
	end

	def filters(items)
		items.all? {|i| i}
	end
	
end end