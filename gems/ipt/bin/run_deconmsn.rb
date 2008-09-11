#!/usr/bin/env ruby 
#:nodoc:all

##########################################################
##
#   David Austin @ UPENN
# 
#   program to loop through RAW or mzXML files in a directory 
#   and extract the dtas from them 
#
#   options include cwd to change dirs
#   and an alternate pXML for the deconmsn
#
#
######################################################
require 'optparse'
require 'ipt/parsers/mgf'


@@switches = [ '-F', '-L', '-B','-T','-I'] #modified for decon msn

@@usage = 'ruby runDeconMsn.rb [-c cwd] [-p pXML_file]'
@@deconcmd = 'DeconMsn'
@@defaultpfile = '/cygdrive/s/sequest/extract_params/deconDefault.pXML'

cwd = nil
pfile = nil
deconoptions = ''
debug = false
mgf = false

opts = OptionParser.new do |opts|
  opts.on("-c SORT") do |c|
    cwd = c
  end

   opts.on("-p SORT") do |p|
    pfile = p
  end

   opts.on("--debug") do |d|
    debug = true
  end

   opts.on("--mgf") do |m|
    mgf = true
   end

end

opts.parse!(ARGV)


# if cwd then change dir

Dir.chdir(cwd) unless cwd.nil?

# now we must read in the params for the decon msn extraction

pfile = @@defaultpfile if pfile.nil?

puts "Reading in params from: #{pfile}"


 rgx = /<option\sswitch="(\S+)">(\S+)<\/option>/

File.open(pfile){|file|
	file.each{|line|


           if line =~ rgx then
	    puts line if debug
		deconoptions += "#{$1}#{$2} " if @@switches.include?("#{$1}")
	  end	

        }

}

deconoptions += "-XMGF " if mgf


#   We need to convert both RAW and mzXML files.  
#   if there are dup files then the mzXML file output 
#   will overwrite it's raw output

#for each raw file do a DEconMSN

Dir.glob("*.{raw,RAW}").each do |r|

     #first make directory
    dirname = r.chomp('.raw')
    dirname = dirname.chomp('.RAW')
    puts "Making directory: #{dirname}" if debug
    system("mkdir #{dirname}")
    system("rm #{dirname}/*.dta #{dirname}/*.mgf #{dirname}/*.txt")
    #copy file over
    puts "cp -v #{r} #{dirname}" if debug
    system("cp -v #{r} #{dirname}")

    #now run decon
    puts "#{@@deconcmd} #{deconoptions} #{dirname}/#{r}" if debug
    system("#{@@deconcmd} #{deconoptions} #{dirname}/#{r} > #{dirname}/deconout.txt") if File.size?(r)

    #cleanup
    puts "rm #{dirname}/#{r}" if debug
    system ("rm #{dirname}/#{r}")
    system "cp #{dirname}/#{dirname}.mgf ." if mgf 
end 


# for each mzXML file do a DeconMsn 

Dir.glob("*.{mzXML}").each do |r|

     #first make directory
    dirname = r.chomp('.mzXML')
    # dirname = dirname.chomp('.raw')
    puts "Making directory: #{dirname}" if debug
    system("mkdir #{dirname}")
    system("rm #{dirname}/*.dta #{dirname}/*.mgf #{dirname}/*.txt")
    #copy file over
    puts "cp -v #{r} #{dirname}" if debug
    system("cp -v #{r} #{dirname}")

    #now run decon
    puts "#{@@deconcmd} #{deconoptions} #{dirname}/#{r}" if debug
    system("#{@@deconcmd} #{deconoptions} #{dirname}/#{r} > #{dirname}/deconout.txt") if File.size?(r)

    #cleanup
    puts "rm #{dirname}/#{r}" if debug
    system ("rm #{dirname}/#{r}")

end 


