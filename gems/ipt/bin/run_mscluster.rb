#!/usr/bin/env ruby 
#:nodoc:all


######################################################################
##
#    David Austin ITMaT @ UPenn
#    Loops through directory and runs 
#    MSClustering on all the mgf files in cwd. 
#
#
#
##############################################

require 'optparse'

usage = 'ruby runMSCluster.rb [-c cwd] '
clustercmd = "MSCluster.exe"
modeldir = "/cygdrive/c/WinShellScripts/Models"
cwd = nil
clusteroptions = ' -assign_charges -list mgfinputs.txt'
debug = false

opts = OptionParser.new do |opts|
  opts.on("-c SORT") do |c|
    cwd = c
  end
  
  opts.on("--debug") do |d|
    debug = true
  end
  
end

opts.parse!(ARGV)


# if cwd then change dir

Dir.chdir(cwd) unless cwd.nil?


# first copy over the models, mkdir tmp out

system "cp -r #{@@modelsdir} ."
system "mkdir out"
system "mkdir tmp"


#for each mgf

Dir.glob("*.{mgf}").each do |f|
  
  # parse f so that we can get the filename
  
  fdir = f.chomp(".mgf")
  
  system "mkdir #{fdir}"
  system "rm #{fdir}/*"
  
  #clean the out and tmp files
  
  system "rm -r out/* tmp/*"
  
  #fix the mgf file
  
  puts "Fixing Decon output for #{f}..\n"
  
  system "ruby -S fix_deconmsn.rb #{f}"
  
  # write inputs for mgf
  
  mgfout = File.open('mgfinputs.txt', "w+")
  mgfout.write("#{f}\n")
  mgfout.close
  
  #cluster the mgf file
  
  puts "Running MSCLuster for #{f}...\n"
  system "#{clustercmd} #{clusteroptions} -name=#{f} > #{fdir}_cluster_out.txt"
  
  #move the file to the dir
  
  puts "Post processing: Mapping, moving and cleaning up for #{fdir}..."
  
  system "cp -v ./out/#{fdir}_0_1.mgf ./#{fdir}"
  
  
  # create mapping xml file, split into dtas
  
  Dir.chdir("#{fdir}") do 
    
    #make map
    
    system "ruby -S map_cluster.rb -i ../#{f} -m ../out/#{fdir}_clust.txt"
    
    #split into dtas
    
    system "ruby -S mgf2dta.rb #{fdir}_0_1.mgf"
    
  end
  
  
  # recreate the mzxml file from the new mgf file TODO
  
  #cleanup
  system "rm tmp/* out/*"
  
end 


