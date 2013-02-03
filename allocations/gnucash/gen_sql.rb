#!/usr/bin/ruby

require '/home/ryan52/csvlib.rb'
require 'date'
require 'securerandom'

db = 'gnucash'

system("echo \"SELECT SUBSTRING(code FROM 0 FOR 5) || '-' || LPAD(SUBSTRING(code FROM 6 FOR 3), 3, '0') AS code, guid, account_type, commodity_guid, commodity_scu, non_std_scu, parent_guid FROM accounts WHERE code NOT LIKE '';\" | psql #{db} | ./psql2csv > current_accounts.csv")
accounts = parse("current_accounts.csv")
currency_guid = eval(`echo 'SELECT DISTINCT currency_guid FROM transactions;' | psql #{db} | ./psql2csv  | tail -1`)

acct_h = {}

accounts.each do |code, guid, account_type, commodity_guid, commodity_scu, non_std_scu, parent_guid|
  acct_h[code] = [guid, account_type, commodity_guid, commodity_scu, non_std_scu, parent_guid]
end

# TODO: this should probably check against the list we have? :P
def new_guid
  SecureRandom.uuid.gsub('-', '')
end

if ARGV.length != 5
  die("Usage: " + $0 + " date pool_subacct input_balances.csv cost_pool_allocations.csv output_file.csv")
end

date = Date.parse(ARGV.shift)

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
    series[acct][pool_subacct] = (-1 * balance).to_i.to_s
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
    unless acct_h.keys.include?(full_acct)
      pool_acct = acct.to_s + "-" + pool_subacct.to_s
      old_guid, account_type, commodity_guid, commodity_scu, non_std_scu, parent_guid = acct_h[pool_acct]
      guid = new_guid
      name = acct_names[acct] + ", " + subacct_names[subacct]
      comments = acct_comments[acct]
      extref = acct_refs[acct]
      acct_h[full_acct] = [guid, account_type, commodity_guid, commodity_scu, non_std_scu, parent_guid]
      # where to get/put extref?
      puts "INSERT INTO accounts(guid, name, account_type, commodity_guid, commodity_scu, non_std_scu, parent_guid, code, description, hidden, placeholder) VALUES ('#{guid}', '#{name}', '#{account_type}', '#{commodity_guid}', #{commodity_scu}, #{non_std_scu}, '#{parent_guid}', '#{full_acct}', '#{comments}', 0, 0);"
    end
    series[acct.to_s][subacct.to_s] = (balance*1).to_i.to_s
    cost_pool_percentages[acct.to_s + "-" + subacct.to_s] = percent
  end
end

series.each do |acct, list|
  tx_guid = new_guid
  num = ''
  post_date = date.to_s
  enter_date = Date.today.to_s
  desc = "Automated cost-pool allocation for subaccount #{pool_subacct}"
  puts "INSERT INTO transactions(guid, currency_guid, num, post_date, enter_date, description) VALUES('#{tx_guid}', '#{currency_guid}', '#{num}', '#{post_date}', '#{enter_date}', '#{desc}');"
  list.each do |subacct, balance|
    new = new_guid
    percent = cost_pool_percentages[acct.to_s + "-" + subacct.to_s]
    extra = percent ? " of #{percent}%" : ""
    acct_guid = acct_h[acct.to_s + "-" + subacct.to_s].first
    msg = "Automated cost-pool allocation#{extra} for subaccount #{pool_subacct}"
    cents = balance.to_i
    puts "INSERT INTO splits(guid, tx_guid, account_guid, memo, action, reconcile_state, reconcile_date, value_num, value_denom, quantity_num, quantity_denom, lot_guid) VALUES('#{new}', '#{tx_guid}', '#{acct_guid}', '#{msg}', '', 'y', '#{enter_date}', #{cents}, 100, #{cents}, 100, '');"
  end
end
