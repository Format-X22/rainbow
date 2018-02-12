require 'moving_average'

class Calculator

	EXPANDS = [100, 90, 80, 70, 60, 50, 40, 30]
	PERCENTS = [5.0, 4.5, 4.0, 3.5, 3.0, 2.5, 2.0, 1.5, 1.0, 0.75, 0.5]
	BASIC_SEMA = 5
	END_SEMA = 300
	BASIC_LEMA = 10
	END_LEMA = 600
	EMA_INDENT = 5
	EMA_MUL_INDENT = 25

	def initialize
		data = Marshal.restore File.read('data.txt')

		EXPANDS.each do |expand|
			PERCENTS.each do |percent|
				iteration(data, expand, percent)
			end
		end
	end

	def iteration(data, expand, percent)
		start_sema = BASIC_SEMA
		sema = start_sema
		lema = BASIC_LEMA

		loop do

			calc(data, expand, percent, sema, lema)

			lema += 5

			if lema / sema > EMA_MUL_INDENT

				loop do
					sema += 5

					break if lema / sema <= EMA_MUL_INDENT
				end
			end

			if lema > END_LEMA
				start_sema += 5
				sema = start_sema
				lema = sema + EMA_INDENT
			end

			if sema > END_SEMA
				break
			end
		end
	end

	def calc(data, expand, percent, sema, lema)
		close = data.map{|v| v[2]}

		state = 'wait'
		sum = 0.0
		order = nil

		data.each.with_index do |tick, index|
			next if index + 1 < lema

			case state
				when 'wait'
					#
				when 'buy'
					#
				when 'sell'
					#
			end
		end

		File.write 'result.txt', "\n", mode: 'a'
	end

end

Calculator.new