#!/usr/bin/ruby

require '/home/ryan52/csvlib.rb'

periods = ARGV.shift
dir = ARGV.shift

code = 930

system("mkdir -p #{dir}/#{code}")

def cleanup_results(results, code, list)
  unless results[code]
    return
  end
  tot = 0.0
  list.each do |frac, ocode|
    tot += frac
    results[ocode] ||= 0.0
    results[ocode] += frac * results[code]
  end
  raise if (1000 * (tot - 1.0)) > 1 or (1000 * (tot - 1.0)) < -1
  results.delete(code)
end

parse(periods).each do |name, d_start, d_end|
  f_name = name
  year, month = f_name.split(" - ")
  f_name = "2009 - Dec" if year.to_i <= 2009 # Dec is Dec, clever

  results = {}
  parse("#{dir}/#{f_name}.csv").each do |a_name, amount|
    sub = a_name.split(". ").first.to_i
    amt = amount.to_f
    results[sub] = amt
  end

  # split up 999 and 998 pools within the main cost pool
  cleanup_results(results, 999, [[0.88, 700], [0.12, 410]])
  cleanup_results(results, 998, [[0.64, 500], [0.36, 930]])

  # split up the 930 shared portion of the cost pool amongst the other
  # members, based on their current share
  t = 0.0
  results.each do |sub_code, val|
    unless [930, 998, 999].include?(sub_code)
      t += val
    end
  end
  cur_shares_full = {}
  results.each do |sub_code, val|
    unless [930, 998, 999].include?(sub_code)
      cur_shares_full[sub_code] = (val / t)
    end
  end
  list = []
  cur_shares_full.each do |k, v|
    list << [v, k]
  end
  cleanup_results(results, 930, list)

  # Now we save the final results
  file = "#{dir}/#{code}/#{name}.csv"
  s = ""
  tocsv(s, "code", "value")
  results.keys.sort.each do |k|
    v = results[k]
    tocsv(s, k, v)
  end
  f = File.open(file, "w+")
  f.write(s)
  f.close
end

