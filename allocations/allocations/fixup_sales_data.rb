#!/usr/bin/ruby

require '/home/ryan52/csvlib.rb'
require 'date'

codes = {:retail => 932, :bulk => 933, :online => 934}

periods = ARGV.shift
dir = ARGV.shift

months = {}
(1..12).each do |x|
  months[x] = Date.parse("01-#{x}-2012").strftime("%b")
end

codes.values.each do |code|
  system("mkdir -p #{dir}/#{code}")
end

values = {}

parse(periods).each do |name, d_start, d_end|
  values[name] = {}
  codes.values.each do |x|
    values[name][x] = {}
  end
end

results = parse("#{dir}/results.csv").each do |month, year, a_name, type, amount|
  key = "#{year} - #{months[month.to_i]}"
  if values[key]
    sub = a_name.split(" ").last
    code = codes[type.to_sym]
    values[key][code][sub] = amount
  end
end

values.each do |name, first|
  first.each do |code, hash|
    file = "#{dir}/#{code}/#{name}.csv"
    s = ""
    tocsv(s, "code", "value")
    hash.each do |key, value|
      tocsv(s, key, value)
    end
    f = File.open(file, "w+")
    f.write(s)
    f.close
  end
end
