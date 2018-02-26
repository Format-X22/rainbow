class Half
	class Options
		attr_accessor :source,
			:green, :red, :blue,
			:take, :margin, :profit,
			:move_window, :move_max,
			:flat_slice, :flat_window, :flat_blue, :flat_red, :flat_green,
			:cross_skip,
			:last,
			:off_profit_log, :off_fail_log, :off_order_log,
			:off_profit, :off_fail

		def initialize(options)
			options.each do |key, value|
				name = "#{key}=".to_sym
				self.send(name, value)
			end
		end
	end
end