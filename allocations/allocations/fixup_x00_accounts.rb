#!/usr/bin/ruby

hundreds = [1, 2, 4]

require '/home/ryan52/csvlib.rb'

periods = ARGV.shift
dir = ARGV.shift

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
  results = {}
  parse("#{dir}/#{f_name}.csv").each do |a_name, amount|
    sub = a_name.to_i
    amt = amount.to_f
    results[sub] = amt
  end

  for i in hundreds
    if results[100 * i]
      t = 0.0
      results.each do |sub_code, val|
        if sub_code > (100 * i) && sub_code < (100 * (i + 1))
          t += val
        end
      end
      cur_shares_full = {}
      results.each do |sub_code, val|
        if sub_code > (100 * i) && sub_code < (100 * (i + 1))
          cur_shares_full[sub_code] = (val / t)
        end
      end
      list = []
      cur_shares_full.each do |k, v|
        list << [v, k]
      end
      cleanup_results(results, 100 * i, list)
    end
  end

  # Now we save the final results
  file = "#{dir}/#{name}.csv"
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
