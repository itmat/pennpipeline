############################################################################################
#######
####
#
#     David Austin - ITMaT @ UPenn
#
#     merge_map.rb - script to merge a cluster mapping file
#     with the original dtas
#     outputs: an xml file
#
#     usage:  ruby merge_map.rb -i <original unclustered mgf> -m <cluster mapping file>
#
#
#
#

require 'optparse'
# require 'rubygems'
require '../lib/itmat/parser/mgf'

include ITMAT::Parser::MGFUtils
usage = 'ruby merge_map.rb -i <original unclustered mgf> -m <cluster mapping file> '
debug = false
mgf_fname = nil
map_fname = nil


opts = OptionParser.new do |opts|
  opts.on("-i SORT") do |i|
    mgf_fname = i
  end
  opts.on("-m SORT") do |m|
    map_fname = m
  end
  opts.on("--debug") do |d|
    debug = true
  end
  
end

opts.parse!(ARGV)

if (mgf_fname.nil? || map_fname.nil?)
  puts usage
  exit 1
end

outxml = File.open(File.basename(mgf_fname), "w+")

#print xml headers

outxml.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n")

#open mgf file and initialize mgf lib
mgf = MGF.new(mgf_fname)

outxml.write("<mgf filename=\"#{mgf.fname}\"\n\n")

#open mapping file 

map = File.open("#{map_fname}")

title = File.basename(mgf_fname)
title.chomp!(".mgf").chomp!(".MGF")

incluster = false

map.each do |l|
  l.chomp!
  case l
  when /^(\D\S+)\s(\d+)\s(\d+\.\d+)\s*$/
    #print cluster tag
    outxml.write("</cluster>\n\n") if incluster
    incluster = true
    #now print cluster tag
    outxml.write("<cluster name=\"#{$1}\" count=\"#{$2}\" mass=\"#{$3}\">\n")
    
  when /^0\s+(\d+)\s+\d+\.\d+\s\d\s*$/
    scan = mgf.get_scan($1)
    unless scan.nil?
      #now we print the dta
      outxml.write("<scan title=\"#{scan.title}\" charge=\"#{scan.charge}\" pepmass=\"#{scan.pepmass}\">\n")
      #now loop through the arrays to construct the mz
      mza = scan.mz
      inta = scan.int
      
      0.upto(mza.size-1) do |i|
        outxml.write("<mz intensity=\"#{inta[i]}\">#{mza[i]}</mz>\n")       
      end     
      
      outxml.write("</scan>\n")
      
    end
    
  end
  
end


#print xml footers
outxml.write("</cluster>\n\n") if incluster
outxml.write("</mgf>\n\n")

