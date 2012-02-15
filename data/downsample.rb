#!/usr/bin/ruby

# parses simple text file with value pairs, and samples them down to a defined resolution

require 'rubygems'
require 'json'
require 'micro-optparse'


def init

  options = Parser.new do |p|
     p.banner = "Custom script to transform a list of lat/lng touples into a heat matrix"
     p.version = "vs 2012-02-11"
     p.option :user, "Choose between julian and pwever", :default => "julian", :value_in_set => ["julian","pwever"]
     p.option :location, "Choose between LA and SF", :default => "la", :value_in_set => ["la","sf"]
     p.option :resolution, "Resolution (dec degree, min or sec)", :default => "1m", :value_matches => /\d+\.?\d?[ms]?/
  end.process!


  resinput    = options[:resolution]
  $value_range = options[:location]=="la" ?  [[-119, -117],[33, 35]] : [[-123, -121],[36.6, 38.5]]
  filename    = options[:user]=="julian" ? "julian-gps-nonull.data" : "pwever-gps-nonull.data"
  filename    = File.join(File.dirname(__FILE__), filename)

  resolutions = resinput.split(',')
  resolutions.each do |res|
    $res_val = res.to_f
    if (res.end_with? "m") then
      $res_val = $res_val / 60
    elsif (res.end_with? "s") then
      $res_val = $res_val / 60 / 60
    end
  
    outfilename = File.join(File.dirname(__FILE__), "%s-%s-%s.json" % [options[:user], options[:location], res])
  
    points = downsample(parse_file(filename))
    origin = find_origin(points)
    center = find_center(points)
    grid_size = get_grid_size(get_axis_ranges(points))
    normalized = normalize(points)
    point_frequency = get_cell_hash(normalize(offset(points, origin)), grid_size)
  
    data = Hash.new()
    data['columns'] = grid_size[0]
    data['rows'] = grid_size[1]
    data['origin'] = origin
    data['center'] = center
    data['resolution'] = $res_val
    data['frequency'] = point_frequency

    File.open(outfilename, 'w') { |f| f.write(data.to_json); f.close() }
    p "Created %s ." % outfilename
  
  end

end









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
    p.map { |val| (val/$res_val).round() * $res_val}
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

def find_center(points)
  min_values = Array.new(points[0])
  max_values = Array.new(points[0])
  points.each do |p|
    p.each_with_index do |val,index|
      min_values[index] = val if val<min_values[index]
      max_values[index] = val if val>max_values[index]
    end
  end
  center = Array.new
  min_values.each_with_index do |val,index|
    center[index] = (min_values[index] + max_values[index]) / 2
  end
  center
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
  ranges.map { |v| (v / $res_val).round }
end

def normalize(points)
  points.map do |point|
    point.map { |value| (value / $res_val).round }
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
    cells[key] += 1
  end
  cells
end

def within_range?(vector)
  vector.each_with_index do |val,index|
    return false if (val < $value_range[index][0] || val > $value_range[index][1])
  end
  return true
end




if $0==__FILE__ then
  init
end