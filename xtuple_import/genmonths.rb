#!/usr/bin/ruby1.8

require 'date'

years = {2011 => 8, 2012 => 9, 2013 => 10, 2007 => 2}

years.each do |year, ypid|
  months = (1..12).map{|x| Date.new(year, x)}
  months.each do |monthstart|
    monthend = ((monthstart + 2)..(monthstart + 35)).select{|x| x.day == 1}.first - 1
    quarter = ((monthstart.month + 2) / 3)
    name = year.to_s + " - " + monthstart.strftime("%b")
    puts "INSERT INTO period (period_start, period_end, period_closed, period_freeze, period_initial, period_name, period_yearperiod_id, period_quarter, period_number) VALUES ('#{monthstart.to_s}', '#{monthend.to_s}', 'f', 'f', 'f', '#{name}', #{ypid}, #{quarter}, #{monthstart.month});"
  end
end
