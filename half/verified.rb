require_relative 'calculator'

T1H = Half.new(
	source: 'data1h.txt',

	green: 25,
	red: 100,
	blue: 250,

	take: 0.12 + 0.01,
	margin: 0.12, # x6.4
	profit: 0.68,

	move_window: 24,
	move_max: 1.12,
	flat_slice: 4,
	flat_window: 24 + 4,
	flat_blue: 0,
	flat_red: 0,
	flat_green: 0.01,
	cross_skip: 2
)