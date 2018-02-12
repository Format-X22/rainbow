require 'moving_average'

class Calculator

	EXPANDS = [100.0, 87.5, 75.0, 62.5, 50.0]
	PERCENTS = [3.0, 2.5, 2.0, 1.5, 1.0, 0.75, 0.5]
	BASIC_SEMA = 5
	END_SEMA = 200
	BASIC_LEMA = 10
	END_LEMA = 600
	EMA_INDENT = 5
	EMA_MUL_INDENT = 20

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

			lema += 1

			if lema / sema > EMA_MUL_INDENT

				loop do
					sema += 1

					break if lema / sema <= EMA_MUL_INDENT
				end
			end

			if lema > END_LEMA
				start_sema += 1
				sema = start_sema
				lema = sema + EMA_INDENT
			end

			if sema > END_SEMA
				break
			end
		end
	end

	def calc(data, expand, percent, sema, lema)
		# start state

		data.each do |tick|
			# state machine
		end
	end

end

Calculator.new