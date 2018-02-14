require 'date'
require 'moving_average'

class MoveAverage

	def initialize
		data = Marshal.restore(File.read('data.txt')).last(288 * 7)
		for_ma = data.map{|v| v[2]}

		result = 0

		state = 'wait'
		short_ma_period = 100
		long_ma_period = 50
		take = 0.003
		safe = 0.002 + take
		margin = 0.01
		profit = 0.15

		break_filter = 0.001

		skip = [short_ma_period, long_ma_period].max + 1
		order = nil
		last = nil
		l_long_ma = nil
		l_short_ma = nil

		data.each.with_index do |tick, index|
			if index < skip
				last = tick

				if index == skip - 1
					l_long_ma = for_ma.sma(index, long_ma_period)
					l_short_ma = for_ma.sma(index, short_ma_period)

					puts Time.at tick.first
				end

				next
			end

			date, open, close, high, low = tick
			l_date, l_open, l_close, l_high, l_low = last

			long_ma = for_ma.sma(index, long_ma_period)
			short_ma = for_ma.sma(index, short_ma_period)

			case state
				when 'wait'
					if long_ma > short_ma
						if
							high > long_ma and # break
							low < long_ma and
							l_high < l_long_ma and # way
							low * (1 + break_filter) < l_long_ma # break filter

							state = 'long'
						end
					else
						if
						    high > short_ma and # break
							low < short_ma and
							l_low > l_short_ma and # way
							low * (1 + break_filter) < short_ma # break filter

							state = 'short'
						end
					end
				when 'long'
					unless order
						puts "BUY at #{Time.at date}"
					end

					order ||= open

					if order * (1 - margin) > low
						result -= 1
						order = nil
						state = 'wait'

						puts "BUY fail #{Time.at date}"
					elsif order * (1 + safe) < high
						result += profit
						order = nil
						state = 'wait'

						puts "BUY profit #{Time.at date}"
					end

				when 'short'
					unless order
						puts "SELL at #{Time.at date}"
					end

					order ||= open

					if order * (1 + margin) < high
						result -= 1
						order = nil
						state = 'wait'

						puts "SELL fail #{Time.at date}"
					elsif order * (1 - safe) > low
						result += profit
						order = nil
						state = 'wait'

						puts "SELL profit #{Time.at date}"
					end
			end

			l_long_ma = long_ma
			l_short_ma = short_ma
			last = tick
		end

		puts result
	end
end

MoveAverage.new