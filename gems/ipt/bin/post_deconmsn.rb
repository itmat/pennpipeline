#!/usr/bin/env ruby 
#:nodoc:all

##########################################################
##
#   AUTHOR: Angel Pizarro @ UPENN
# 
#   program to loop through DeconMSn output MGF files in a directory 
#   and post-process them to add RETINSEC and fix TITLE and CHARGE  
#
#
######################################################
if (ARGV[0] && File.directory?(ARGV[0]) && ARGV[0] != ".")
  Dir.chdir ARGV[0]
end

Dir.glob("*.mgf").each do |f|
  system("mv #{f} #{f}.bkp")
  i = File.open("#{f}.bkp") 
  o = File.open(f,'w')
  charge = 1
  i.each do |l|
    case l.chomp! 
    when /^(TITLE=.+)\.(\d)\.dta$/
      o.puts "#{$1}.#{$2}"
      charge = $2
    when /^CHARGE/
      o.puts "CHARGE=#{charge}+"
    else 
      o.puts l
    end
  end
  o.close()
  i.close()
end
