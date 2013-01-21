require 'csv'

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
