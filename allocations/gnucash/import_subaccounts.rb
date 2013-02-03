#!/usr/bin/ruby

require '/home/ryan52/csvlib.rb'

puts "DROP TABLE IF EXISTS subaccounts;"
puts "CREATE TABLE subaccounts(code text, description text);"

parse("/home/ryan52/subaccounts.csv").each do |code, text|
  puts "INSERT INTO subaccounts(code, description) VALUES ('#{code}', '#{text}');"
end
