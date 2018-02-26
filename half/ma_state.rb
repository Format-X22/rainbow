class Half
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
end