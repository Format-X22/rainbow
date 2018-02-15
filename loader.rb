require 'json'
require 'http'
require 'time'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/integer/time'

#https://www.bitmex.com/api/udf/history?symbol=XBTUSD&resolution=5&from=1517963045&to=1518395105

url = 'https://www.bitmex.com/api/udf/history?symbol=XBTUSD'
mul = 10000 * 60

resolution = 5
from_start = 365.days.ago.to_i
to_end = Time.now.to_i
from = from_start
to = from_start + mul * resolution

result_hash = {}
result = []

loop do
	if from > to_end
		break
	end

	data = JSON.parse HTTP.get("#{url}&resolution=#{resolution}&from=#{from}&to=#{to}").to_s

	puts data['t'].length

	data['t'].each.with_index do |date, index|
		result_hash[date] = [date, data['o'][index], data['c'][index], data['h'][index], data['l'][index]]
	end

	from = from + (mul * resolution) - 1000
	to = from + (mul * resolution) - 1000
end

result_hash.each do |key, data|
	result << data
end

File.write 'data.txt', Marshal.dump(result)