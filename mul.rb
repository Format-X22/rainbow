data = Marshal.restore(File.read('data/5m.txt'))

data = data.each_slice(6).to_a.map do |ticks|
	date = ticks.first[0]
	open = ticks.first[1]
	close = ticks.last[2]
	high = ticks.map{|v| v[3]}.max
	low = ticks.map{|v| v[4]}.min

	[date, open, close, high, low]
end

File.write 'data/30m.txt', Marshal.dump(data)