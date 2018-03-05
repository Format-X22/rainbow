module Polymorph class Options
	attr_accessor :source, :last,
		:green, :red,
		:take, :margin, :profit,
		:off_profit_log, :off_fail_log, :off_order_log,
		:off_profit, :off_fail

	def initialize(options)
		options.each do |key, value|
			name = "#{key}=".to_sym
			self.send(name, value)
		end
	end
end end