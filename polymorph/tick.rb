module Polymorph class Tick
	attr_reader :date, :open, :close, :high, :low

	def initialize(data)
		@date, @open, @close, @high, @low = data
	end
end end