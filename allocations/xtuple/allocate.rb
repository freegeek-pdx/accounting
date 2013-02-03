#!/usr/bin/ruby

# To split the subacct/names
# sed -e '1 s/subaccount/subaccount,description/' -e 's/\. /","/' allocations.csv

require 'csv'

join_with = '-'

def tocsv(s, *a)
  a = a.flatten
  CSV.generate_row(a, a.length, s)
end

def parse(filename)
  input = CSV.parse(File.read(filename))
  # remove header line
  input.shift if input[0] and input[0][0] and input[0][0].to_i == 0
  return input
end

def die(err)
  puts "Error: #{err}"
  exit 1
end

if ARGV.length != 3
  die("Usage: " + $0 + " input_balances.csv cost_pool_allocations.csv output_file.csv")
end

accounts_initial = {}

input = parse(ARGV[0])
input.each do |acct, name, comment, ref, bal|
  accounts_initial[acct] = bal.to_f
end

allocation_amounts = {}
allocations_percentages = {}
allocation_total = 0.0

allocations = parse(ARGV[1])
allocations.each do |subacct, count|
  count = count.to_f
  subacct = subacct.split(/[. ]/)[0]
  allocation_total += count
  allocation_amounts[subacct] = count
end

allocation_amounts.each do |k, v|
  allocations_percentages[k] = v / allocation_total
end

final_balances = {}

result = ""

largest_to_smallest = allocations_percentages.to_a.sort_by(&:last).reverse.map(&:first)
individual_allocation_percentages = {}

accounts_initial.each do |acct, start_bal|
  start_bal = ((start_bal * 100) + (start_bal > 0 ? 0.05 : -0.05)).to_i
  end_bal = start_bal
#  if start_bal != 0
#    puts start_bal
#    puts end_bal
#    puts ""
#  end
  init_val = end_bal
  final_val = 0

  allocations_percentages.each do |subacct, fraction|
    key = acct + join_with + subacct

    percent = fraction * 100
    cents = (fraction * start_bal).round

    individual_allocation_percentages[key] = percent
    end_bal -= cents
    final_val += cents
    final_balances[key] = cents
  end

  to_add = []
  while end_bal != 0.0
    if to_add.length == 0
      to_add = largest_to_smallest.dup
    end

    subacct = to_add.shift
    key = acct + join_with + subacct

    if end_bal > 0
      final_balances[key] += 1
      final_val += 1
      end_bal -= 1
    else
      final_balances[key] -= 1
      final_val -= 1
      end_bal += 1
    end
  end
end

final_balances.each do |key, value|
  percent = individual_allocation_percentages[key]
  tocsv(result, key, sprintf("%.2f", percent), sprintf("%.2f", value/100.0))
end

# clean up the result, sorting and adding header
a = result.split("\n")
result = ""
tocsv(result, "account", "percentage", "balance")
result += a.sort.join("\n")

f = File.open(ARGV[2], 'w')
f.write(result + "\n")
f.close
