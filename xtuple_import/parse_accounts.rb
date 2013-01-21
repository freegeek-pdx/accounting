#!/usr/bin/ruby

require 'nokogiri'
include Nokogiri
require 'csv'

root_node = Nokogiri::XML(File.read("accounts.qsf"))

lookfor = ['desc', 'guid', 'parent-account', 'name', 'desc', 'notes', 'account-type', 'code']
toprint = ['account-type', 'account-subtype', 'account-number', 'subaccount-number', 'parent-code', 'name', 'desc', 'notes', 'profit-center']

accounts = {}
account_list = []

root_node.children.first.children[1].children.each do |object|
  if object.name == "object" && object.attributes["type"] && object.attributes["type"].value == "Account"
    h = {}
    object.children.each do |sub|
      if sub.attributes["type"] && lookfor.include?(sub.attributes["type"].value)
        h[sub.attributes["type"].value] = sub.content
      end
    end
    if h["account-type"] != "ROOT" and ((h['code'] && h['code'].length > 0) or (h['description'] && h['description'].length > 0))
      accounts[h["guid"]] = h
      account_list << h["guid"]
    end
  end
end

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

a_types = {"Equity" => "Q", "Income" => "R", "Asset" => "A", "Expense" => "E", "Liability" => "L"}
for i in ["Cash", "Bank", "Receivable"]
  a_types[i] = "A"
end
a_types.keys.each do |k|
  a_types[k.upcase] = a_types[k]
end

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

account_list.each do |k|
  acct = accounts[k]
  parent = accounts[acct['parent-account']]
  acct['parent-code'] = parent['code'] if parent
  code_parts = acct['code'].split("-")
  first, second = code_parts
  acct['account-number'] = first
  acct['subaccount-number'] = second ? sprintf("%3d", second.to_i).gsub(" ", "0") : "000"
  num = acct['account-number'].to_i
  acct['account-type'] = a_types[acct['account-type']] || acct['account-type']
  acct['profit-center'] = determine_profit_center(acct['subaccount-number'], acct['account-type'])
  acct['account-subtype'] = determine_account_type(num, acct['subaccount-number'])
end

account_list = account_list.sort_by{|k| accounts[k]['code']}
# NO LONGER NEEDED: .select{|k| acct = accounts[k]; acct['account-number'] == "7000" || ((!acct['account-number'].match(/000/)) || acct['parent-code'])}

def tocsv(s, a)
  CSV.generate_row(a, a.length, s)
end

s = ""
tocsv(s, toprint)
account_list.each do |k|
  acct = accounts[k]
  tocsv(s, toprint.map{|x| acct[x]})
end
puts s

# then pull /guid[type='guid']
# maps from /guid[type='parent-account']
# get: /string[type='name'], /string[type='desc'], /string[type='notes'], /string[type='account-type'], /string[type='code']

# .content
