#!/usr/bin/ruby

require 'csv'
require 'date'

db = 'xtuple'

system("~/generate_account_id_hash.sh #{db} > ~/accounts.rb")
account_id_hash = eval(File.read('/home/ryan52/accounts.rb'))

@account_types =   [
                   ["EXP", 8700, 9000],
                   ["BUS", 8600, 8699],
                   ["OTH", 8500, 8599],
                   ["UNR", 8450, 8450],
                   ["UNP", 8450, 8450, "210"],
                   ["3PSC", 8430, 8449],
                   ["1PSC", 8430, 8449, "120", "130", "140", "160"],
                   ["2PSC", 8400, 8429],
                   ["TM", 8300, 8399],
                   ["FAC", 8200, 8299],
                   ["NPG", 8100, 8199],
                   ["CON", 7500, 7999],
                   ["SAL", 7200, 7499],
                   [nil, 7000, 7000],
                   ["NAR", 6900, 6999],
                   ["SPI", 5800, 5999],
                   ["IO", 5400, 5499],
                   ["IV", 5300, 5399],
                   ["II", 5310, 5319],
                   ["ADJ4", 5157, 5159],
                   ["ADJ3", 5154, 5156],
                   ["ADJ7", 5151, 5153],
                   [nil, 5150, 5150],
                   ["4PSR", 5140, 5149],
                   ["3PSR", 5130, 5139],
                   ["2PSR", 5120, 5129],
                   ["PSR", 5100, 5100],
                   ["IC", 4400, 4599],
                   ["TRG", 4200, 4399],
                   ["DC", 4000, 4199],
                   [nil, 4000, 4000, "001"],
                   ["EC", 3000, 3999],
                   ["LTL", 2700, 2999],
                   ["CL", 2100, 2699],
                   ["AP", 2000, 2099],
                   ["AD", 1700, 1999],
                   ["FA", 1600, 1699],
                   ["CAS", 1430, 1599],
                   ["IN", 1400, 1429],
                   ["AR", 1100, 1399],
                   ["CA", 1000, 1099]]

def determine_profit_center(subaccnt, type)
  if subaccnt && ['R', 'E'].include?(type)
    value = subaccnt.to_i
    hundred = value - (value % 100)
    center = hundred
    if center == 800
      center = 700
    elsif center == 600
      center = 500
    elsif center == 400
      ten = value - (value % 10) - hundred
      center = hundred + ten
    elsif center == 900
      center = value
    end
    return sprintf("%3d", center).gsub(" ", "0")
  else
    return '000'
  end
end

def determine_account_type(num, subaccnt)
  ret = nil
  @account_types.each do |n, l, h, *opts|
    if num >= l && num <= h && (opts.length == 0 || opts.include?(subaccnt))
      ret = n
    end        
  end
  return ret
end

def determine_type(accnt_num)
  accnt_num < 7000 ? "R" : "E"
end

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

if ARGV.length != 5
  die("Usage: " + $0 + " date pool_subacct input_balances.csv cost_pool_allocations.csv output_file.csv")
end

date = Date.parse(ARGV.shift)

@last_journal = `echo 'SELECT MAX(gltrans_journalnumber) FROM gltrans;' | psql #{db} | sed '3 !d'`.strip.to_i
@last_sequence = `echo 'SELECT MAX(gltrans_sequence) FROM gltrans;' | psql #{db} | sed '3 !d'`.strip.to_i

existing = `echo "SELECT accnt_number || '-' || accnt_sub FROM accnt;" | psql #{db} | sed -r -e '/^ / !d' -e 's/\\|/,/g' -e 's/[ ]+,[ ]+/","/g' -e 's/^[ ]+//' -e '1 d'`.split("\n").map{|x| x.strip}

pool_subacct = ARGV[0]
inputs = parse(ARGV[1]) # acct, name
subaccounts = parse(ARGV[2]) # subacct, name
results = parse(ARGV[3]) # acct, percent, balance

series = {} # maps acct -> map { subacct -> bal_diff }
acct_names = {}
subacct_names = {}
acct_comments = {}
acct_refs = {}

inputs.each do |acct, name, comment, ref, balance|
  balance = balance.to_f
  s_id = acct.to_i
  acct_names[s_id] = name
  series[acct] = {}
  if balance != 0.0
    series[acct][pool_subacct] = (-1 * balance).to_s
    acct_comments[s_id] = comment
    acct_refs[s_id] = ref
  end
end

subaccounts.each do |code, name|
  s_id = code.to_i
  subacct_names[s_id] = name
end

count = 0

cost_pool_percentages = {}

results.each do |full_acct, percent, balance|
  balance = balance.to_f
  if balance != 0.0
    acct, subacct = full_acct.split("-").map{|x| x.to_i}
    unless existing.include?(full_acct)
      type = determine_type(acct)
      subtype = determine_account_type(acct, subacct)
      profit_center = determine_profit_center(subacct, type)
      name = acct_names[acct] + ", " + subacct_names[subacct]
      comments = acct_comments[acct]
      extref = acct_refs[acct]
      puts "INSERT INTO accnt(accnt_type, accnt_subaccnttype_code, accnt_number, accnt_sub, accnt_descrip, accnt_comments, accnt_extref, accnt_profit, accnt_company) VALUES ('#{type}','#{subtype}','#{acct}','#{subacct}','#{name.gsub("'", "''")}','#{comments.gsub("'", "''")}','#{extref.gsub("'", "''")}','#{profit_center}', '01');"
      count += 1
    end
    series[acct.to_s][subacct.to_s] = balance.to_s
    cost_pool_percentages[acct.to_s + "-" + subacct.to_s] = percent
  end
end

if count > 0
  puts "ERROR: Please create the required accounts shown above then run this script again"
  exit
end

series.each do |acct, list|
  @last_journal += 1
  @last_sequence += 1
  journ = @last_journal
  seq = @last_sequence
  list.each do |subacct, balance|
    percent = cost_pool_percentages[acct.to_s + "-" + subacct.to_s]
    extra = percent ? " of #{percent}%" : ""
    puts "INSERT INTO gltrans(gltrans_sequence, gltrans_journalnumber, gltrans_accnt_id, gltrans_rec, gltrans_notes, gltrans_amount, gltrans_date, gltrans_created, gltrans_source, gltrans_doctype, gltrans_misc_id, gltrans_posted) VALUES (#{@last_sequence}, #{@last_journal}, #{account_id_hash[acct.to_s + "-" + subacct.to_s]}, 't', 'Automated cost-pool allocation#{extra} for subaccount #{pool_subacct}', #{balance}, '#{date.to_s}', '#{Date.today.to_s}', 'JE', 'G/L', -1, 't');"
  end
end
