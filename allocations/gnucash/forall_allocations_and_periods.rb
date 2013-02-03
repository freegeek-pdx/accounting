#!/usr/bin/ruby

require '/home/ryan52/csvlib.rb'

periods = ARGV.shift

# 931 allocates to 930
# 930 allocates to 932-934
# (NOTE: flow determined with: grep ^93 allocation_data/*/*.csv | sed 's/[\/,]/:/g' | cut -d : -f 2,4 | sort -u)
for code in [931, 930, 932, 933] #, 934]
  parse(periods).each do |name, d_start, d_end|
    year, month = name.split(" - ")
  # DEBUG: prepend ["echo"] + 
    system((ARGV + [year, month, code, d_end, "allocation_data/#{code}/#{year}_#{month}.csv"]).join(" "))
  end
end

puts "= Importing subaccounts into gnucash ="
system('./import_subaccounts.rb | psql gnucash --quiet')
system('cat find_problems.sql | psql gnucash --quiet')
