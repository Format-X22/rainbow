require 'moving_average'

module Polymorph class MA
	attr_reader :green, :red, :l_green, :l_red

	def initialize(data, *periods)
		@data = data.map{|v| v[2]}
		@periods = periods
	end

	def calc_ma(index)
		@l_green = @green
		@l_red = @red

		@green = @data.sma(index, @periods[0])
		@red = @data.sma(index, @periods[1])
	end

end end