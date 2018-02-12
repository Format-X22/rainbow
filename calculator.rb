require 'moving_average'

data = Marshal.restore File.read('data.txt')

expands = [100.0, 87.5, 75.0, 62.5, 50.0]
percents = [3.0, 2.5, 2.0, 1.5, 1.0, 0.75, 0.5]
basic_sema = 5
end_sema = 200
basic_lema = 10
end_lema = 600
ema_indent = 5
ema_mul_indent = 20

expands.each do |expand|
	percents.each do |percent|
		start_sema = basic_sema
		sema = start_sema
		lema = basic_lema

		loop do

			#

			lema += 1

			if lema / sema > ema_mul_indent

				loop do
					sema += 1

					break if lema / sema <= ema_mul_indent
				end
			end

			if lema > end_lema
				start_sema += 1
				sema = start_sema
				lema = sema + ema_indent
			end

			if sema > end_sema
				break
			end
		end
	end
end