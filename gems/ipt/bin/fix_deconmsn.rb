#!/usr/bin/env ruby 
#:nodoc:all

##############################   
################
#
#  David Austin ITMaT @ UPenn
#  Script to loop through an MGF file and
#  Split up 2+ and 3+ charged scans 
#  
#  usage: ruby fix_deconmsn.rb <filename>

#first open file


require 'optparse'
require 'ipt/parsers/mgf'
include IPT::Parsers


exit 1 if ARGV[0].nil?

ins = File.open("#{ARGV[0]}")
outs = File.open("#{ARGV[0]}.tmp", "w+")

title_rgx = /.+(\d)\.dta/
charge_rgx = /CHARGE=2\+ and 3\+/

charge = 0
count = 0


ins.each do |l|

  if (l =~ title_rgx)
    charge = $1
  end

  if (l =~ charge_rgx) then
    outs.write("CHARGE=#{charge}+\n")
    count+=1
  else
    outs.write(l)
  end

end

ins.close
outs.close

puts "Altered #{count} scans.\n"

`rm #{ARGV[0]}`
`mv #{ARGV[0]}.tmp #{ARGV[0]}`




