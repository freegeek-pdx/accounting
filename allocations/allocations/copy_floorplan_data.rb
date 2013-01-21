#!/usr/bin/ruby

require '/home/ryan52/csvlib.rb'

period = ARGV.shift
alloc = ARGV.shift
dir = ARGV.shift

system("mkdir #{dir}/931")

parse(period).each do |name, d_start, d_end|
  system("cp #{alloc} \"#{dir}/931/#{name}.csv\"")
end
