#!#ruby
# This script will convert the ANSYS csv file into VTK unstructured grid format
# to be read into Paraview.
# => ARG1 - Working directory that hosts csv file
# => ARG2 - Basename of csv file
require 'pathname'

jobdir = ARGV[0]
prefix = ARGV[1]

jobpath = Pathname.new(jobdir)
csv_file = jobpath + "#{prefix}.csv"
vtu_file = jobpath + "#{prefix}.vtu"

start_modeshape = false
start_nodes = false
start_elements = false
start_offsets = false
start_types = false

iter = 0
node_hash = {}
node_iter = 0
num_elements = 0
max_box = 0
scale = 1
File.open(vtu_file, 'w') do |f|
  f.puts "<VTKFile type=\"UnstructuredGrid\" version=\"1.0\" " \
    "byte_order=\"LittleEndian\" header_type=\"UInt64\">"
  f.puts "  <UnstructuredGrid>"
  if File.exist?(csv_file)
    File.foreach(csv_file) do |line|
      if line.include? "EOF"
        f.print "\n" if iter > 0
        f.puts "        </DataArray>"
        f.puts "        <DataArray type=\"Int64\" Name=\"offsets\" " \
          "format=\"ascii\">"
        f.print "          "
        start_offsets = true
        break
      end

      if start_elements
        e = line.split(',') unless line.nil?
        e0, e1, e2 = e[0].strip, e[1].strip, e[2].strip
        if iter == 0
          f.print "          #{node_hash[e0]} #{node_hash[e1]} " \
            "#{node_hash[e2]} "
          iter += 1
        elsif iter == 1
          f.print "#{node_hash[e0]} #{node_hash[e1]} #{node_hash[e2]}\n"
          iter = 0
        end
        next
      elsif line.include? "STARTELEMENTS"
        iter = 0
        f.print "\n"
        f.puts "        </DataArray>"
        f.puts "      </Points>"
        f.puts "      <Cells>"
        f.puts "        <DataArray type=\"Int64\" Name=\"connectivity\" " \
          "format=\"ascii\">"
        start_elements = true
        next
      end

      if start_nodes
        line = line.gsub(/\.E/, ".0E")
        n = line.split(',') unless line.nil?
        node_hash["#{n[0].strip}"] = node_iter
        node_iter += 1
        if iter < 2
          f.print "#{n[1].to_f} #{n[2].to_f} #{n[3].to_f} "
          iter += 1
        else
          f.print "\n"
          f.print "          #{n[1].to_f} #{n[2].to_f} #{n[3].to_f} "
          iter = 1
        end
        next
      elsif line.include? "STARTNODES"
        iter = 0
        f.print "\n"
        f.puts "        </DataArray>"
        f.puts "      </PointData>"
        f.puts "      <Points>"
        f.puts "        <DataArray type=\"Float64\" Name=\"Points\" " \
          "NumberOfComponents=\"3\" format=\"ascii\">"
        f.print "          "
        start_nodes = true
        next
      end

      if line.include? "MODE"
        iter = 0
        mode_header = line.split(',')
        mode = mode_header[1]
        freq = mode_header[2]
        max_d = [mode_header[3].to_f.abs, mode_header[4].to_f.abs, mode_header[5].to_f.abs,
          mode_header[6].to_f.abs, mode_header[7].to_f.abs, mode_header[8].to_f.abs].max
        scale = 0.05 * max_box / max_d
        puts max_box, max_d, scale
        if start_modeshape
          f.print "\n"
          f.puts "        </DataArray>"
        end
        f.puts "        <DataArray type=\"Float64\" Name=\"Mode #{mode.to_i - 6}(#{freq}Hz)\" " \
          "NumberOfComponents=\"3\" format=\"ascii\">"
        f.print "          "
        start_modeshape = true
        next
      elsif start_modeshape
        d = line.split(',') unless line.nil?
        if iter < 2
          f.print "#{d[1].to_f * scale} #{d[2].to_f * scale} #{d[3].to_f * scale}"
          iter += 1
        else
          f.print "\n"
          f.print "          #{d[1].to_f * scale} #{d[2].to_f * scale} #{d[3].to_f * scale} "
          iter = 1
        end
        next
      end

      header = line.split(',') unless line.nil?
      num_nodes, num_elements = header[0].strip, header[1].strip
      max_box = [header[2].to_i.abs + header[5].to_i.abs, header[3].to_i.abs +
        header[6].to_i.abs, header[4].to_i.abs + header[7].to_i.abs].max
      f.puts "    <Piece NumberOfPoints=\"#{num_nodes}\" " \
        "NumberOfCells=\"#{num_elements}\">"
      f.puts "      <PointData>"
    end
  end

  if start_offsets
    e = 1
    iter = 0
    while e < num_elements.to_i + 1 do
      if iter < 5
        f.print "#{e*3} "
        iter += 1
      else
        f.print "#{e*3}\n"
        f.print "          " unless e == num_elements.to_i
        iter = 0
      end
      e += 1
    end
    f.print "\n" if iter > 0
    f.puts "        </DataArray>"
    f.puts "        <DataArray type=\"UInt8\" Name=\"types\" format=\"ascii\">"
    f.print "          "
    start_types = true
  end

  if start_types
    e = 1
    iter = 0
    while e < num_elements.to_i + 1 do
      if iter < 5
        f.print "5 "
        iter += 1
      else
        f.print "5\n"
        f.print "          " unless e == num_elements.to_i
        iter = 0
      end
      e += 1
    end
    f.print "\n" if iter > 0
    f.puts "        </DataArray>"
    f.puts "      </Cells>"
    f.puts "    </Piece>"
    f.puts "  </UnstructuredGrid>"
    f.puts "</VTKFile>"
  end
end
