#!/usr/bin/ruby

# parses simple text file with value pairs, and samples them down to a defined resolution

require 'rubygems'
require 'json'


RESOLUTION = 0.0075
MAX_FREQUENCY = 20
VALUE_RANGES = [
  [-119, -117], # longitude
  [33, 35] # latitude
] # Los Angeles
# VALUE_RANGES = [
#   [-123, -121], # longitude
#   [36.6, 38.5] # latitude
# ] # San Francisco

filename = File.join(File.dirname(__FILE__), "pwever-gps-nonull.data")
outfilename = File.join(File.dirname(__FILE__), "pwever-la-%s.json" % RESOLUTION)


def parse_file(filename)
  points = []
  file = File.new(filename, "r")
  file.each_line() do |line|
  	vector = line.split().map { |val| val.to_f }
    points.push(vector) if within_range?(vector)
  	#break if file.lineno > 10000
  end
  file.close()
  points
end

def downsample(points)
  points.map do |p|
    p.map { |val| (val/RESOLUTION).round() * RESOLUTION}
  end
end

def find_origin(points)
  origin = Array.new(points[0])
  points.each do |p|
    p.each_with_index do |val,index| 
      origin[index] = val if val < origin[index]
    end
  end
  origin
end

def get_axis_ranges(points)
  min_values = Array.new(points[0])
  max_values = Array.new(points[0])
  points.each do |point|
    point.each_with_index do |value,index|
      min_values[index] = value if (value<min_values[index])
      max_values[index] = value if (value>max_values[index])
    end
  end
  ranges = []
  min_values.each_with_index do |value,index|
    ranges[index] = (min_values[index]-max_values[index]).abs
  end
  ranges
end

def get_grid_size(ranges)
  ranges.map { |v| (v / RESOLUTION).round }
end

def normalize(points)
  points.map do |point|
    point.map { |value| (value / RESOLUTION).round }
  end
end

def offset(points, offset)
  points.map do |p|
    registered = []
    p.each_with_index do |v,i|
      registered[i] = v - offset[i]
    end
    registered
  end
end

def get_cell_hash(points, grid_size)
  cells = Hash.new(0)
  points.each do |p|
    key = p[0] + p[1]*grid_size[0]
    cells[key] += 1 if cells[key] < MAX_FREQUENCY
  end
  cells
end

def within_range?(vector)
  vector.each_with_index do |val,index|
    return false if (val < VALUE_RANGES[index][0] || val > VALUE_RANGES[index][1])
  end
  return true
end



points = downsample(parse_file(filename))
origin = find_origin(points)
grid_size = get_grid_size(get_axis_ranges(points))
normalized = normalize(points)
point_frequency = get_cell_hash(normalize(offset(points, origin)), grid_size)
data = Hash.new()
data['columns'] = grid_size[0]
data['rows'] = grid_size[1]
data['origin'] = origin
data['resolution'] = RESOLUTION
data['frequency'] = point_frequency

File.open(outfilename, 'w') { |f| f.write(data.to_json); f.close() }
p "Done"
