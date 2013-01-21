#!/usr/bin/ruby

require '/home/ryan52/csvlib.rb'

periods = ARGV.shift
directory = ARGV.shift

parse(periods).each do |name, d_start, d_end|
  # DEBUG: prepend ["echo"] + 
  `#{(ARGV + [d_start, d_end]).join(" ")} | ~/psql2csv > "#{directory}/#{name}.csv"`
end
