require_relative '../algo'

Polymorph::Algo.new(
	source: 'data/5m.txt',

	green: 50,
	red: 100,

	take: 0.12 + 0.01,
	margin: 0.12, # x6.4
	profit: 0.68,

	#last: 24 * 365,
	#off_profit_log: true,
	#off_fail_log: true,
	#off_order_log: true,
	#off_profit: true,
	#off_fail: true
)