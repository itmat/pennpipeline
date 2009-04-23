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
#   and an alternate pXML for the extractmsn
#
#
######################################################
require 'optparse'
require 'ipt/parsers/mgf'


@@switches = [ '-F', '-L', '-B','-T','-I', '-M', '-S', '-G', '-A', '-R', '-C', '-E', '-r' ] #modified for extract msn

@@usage = 'ruby -S run_extractmsn.rb [-c cwd] [-p pXML_file]'
@@extractcmd = 'extract_msn -X '
@@defaultpfile = '/cygdrive/s/sequest/extract_params/extractDefault.pXML'

cwd = nil
pfile = nil
extractoptions = ''
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

# now we must read in the params for the extract msn extraction

pfile = @@defaultpfile if pfile.nil?

puts "Reading in params from: #{pfile}"


 rgx = /<option\sswitch="(\S+)">(\S+)<\/option>/

File.open(pfile){|file|
	file.each{|line|


           if line =~ rgx then
	    puts line if debug
		extractoptions += "#{$1}#{$2} " if @@switches.include?("#{$1}")
	  end	

        }

}

#   We need to convert RAW   


#for each raw file do a ExtractMSN

Dir.glob("*.{raw,RAW}").each do |r|




    #first make directory
    dirname = r.chomp('.raw')
    dirname = dirname.chomp('.RAW')
    puts "Making directory: #{dirname}" if debug
    system("mkdir #{dirname}")
    system("rm #{dirname}/*.dta #{dirname}/*.mgf #{dirname}/*.txt")

    #now run extract
    puts "#{@@extractcmd} #{extractoptions} -D#{dirname} #{r}" if debug
    if File.size?(r)	
       ps = IO.popen("#{@@extractcmd} #{extractoptions} -D#{dirname} #{r} 2>&1")
       pout = ps.gets
       # count the dtas.  number of $'s
       dta_count = pout.count('$')
	puts "Created #{dta_count} dta files from #{r}"
       ps.close
       
	num_removed = 0
       ps = IO.popen("/usr/bin/find #{dirname}/*.dta -size -24c -exec rm -vf {} \\;")
	num_removed = ps.readlines.size
	ps.close
      
	puts "Removed #{num_removed} small dtas from #{dirname}"
        
    end	       
   

end 

