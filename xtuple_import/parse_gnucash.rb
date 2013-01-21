#!/usr/bin/ruby

# TODO: from xtuple SELECT(MAX ...
sequence_number = 0
journal_number = 0

require 'zlib'
require 'nokogiri'
include Nokogiri
require 'csv'

account_id_hash = eval(File.read('./accounts.rb')) # ryan52@lima:~$ ./generate_account_id_hash.sh > accounts.rb

content = nil
Zlib::GzipReader.open('../current.gnucash') {|gz|
  content = gz.read
}

root_node = Nokogiri::XML(content).root

accounts = root_node.xpath("//gnc:account")
accounts_guid_hash = {}
accounts.each do |accnt|
  guid = accnt.xpath(".//act:id[@type='guid']").first.content
  begin
    code = accnt.xpath(".//act:code").first.content
  rescue
    #puts "no code?"
    next
  end
  if ! code.include?("-")
    code += "-000"
  end
  accounts_guid_hash[guid] = code
end

accounts_guid_id_hash = {}

accounts_guid_hash.each do |guid, code|
  code_a = code.split("-")
  code = code_a.first + "-" + sprintf("%3d", code_a.last.to_i).gsub(" ", "0")
  if accnt_id = account_id_hash[code]
    accounts_guid_id_hash[guid] = accnt_id
  else
    raise "Can't find code: #{code}"
  end
end

# debug code:
#accounts_guid_id_hash.each do |guid, a_id|
#  puts "#{guid} => #{a_id}"
#end

transactions = root_node.xpath("//gnc:transaction")

def tocsv(s, a)
  CSV.generate_row(a, a.length, s)
end

def pcsv(*a)
  a = a.flatten
  s = ""
  tocsv(s, a)
  puts s
  return s
end

yn_t = {'y' => 't', 'n' => 'f', 'c' => 'f'}

def parse_date(node, xpath)
  node.xpath(xpath).first.xpath(".//ts:date").first.content.strip
end

gltrans_source = 'JE'
gltrans_doctype = 'G/L'
gltrans_misc_id = -1
pcsv("empty_description", "sequence", "journal", "reconciled", "account_id", "description", "amount", "date_posted", "date_entered", "gltrans_source", "gltrans_doctype", "gltrans_misc_id")
transactions.each do |trans|
  main_description = trans.xpath('.//trn:description').first.content
  sequence_number += 1
  journal_number += 1
  # are these dates right?
  date_posted = parse_date(trans, ".//trn:date-posted")
  date_entered = parse_date(trans, ".//trn:date-entered")
  trans.xpath('.//trn:split').each do |split|
    reconciled = yn_t[split.xpath('.//split:reconciled-state').first.content]
    accnt_guid = split.xpath(".//split:account[@type='guid']").first.content
    accnt_code = accounts_guid_id_hash[accnt_guid]
    this_description = main_description
    if memo = split.xpath(".//split:memo").first
      this_description += ": " + memo.content
    end
    amount = -1 * eval(split.xpath(".//split:value").first.content + ".0")
    if amount != 0 and accnt_code != nil
      pcsv("", sequence_number, journal_number, reconciled, accnt_code, this_description, amount, date_posted, date_entered, gltrans_source, gltrans_doctype, gltrans_misc_id)
    end
  end
end

