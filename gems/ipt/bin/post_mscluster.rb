module MGFProcess
  def self.post_process(mgf)
    system("cp #{mgf} #{mgf}.bkp")
    input = File.open("#{mgf}.bkp")
    output = File.open("#{mgf}", 'w')
    masses = []
    ttl = nil
    chrg = nil
    pepmass = nil
    do_3_charge = false
    input.each do |l|
      l.chomp!
      case l
      when /^TITLE=(.+)/
        ttl = $1 
      when /CHARGE=(\d)/
        chrg = $1.to_i
      when /PEPMASS/
        pepmass = l
      when /^END/
        if chrg.nil?
          # found a condition where the cluster members are evenly
          # ditributed in charge state. Hence charge never given
          chrg = 2
          do_3_charge = true
        end
        output.puts("BEGIN IONS")
        ttl =~ /^(.+)\.(\d+)$/
        output.puts("TITLE=#{$1}.#{$2}.#{$2}.#{chrg}")
        output.puts("CHARGE=#{chrg}+")
        output.puts(pepmass)
        output.puts(masses.join("\n"))
        output.puts("END IONS")

        if do_3_charge
          output.puts("BEGIN IONS")
          ttl =~ /^(.+)\.(\d+)$/
          output.puts("TITLE=#{$1}.#{$2}.#{$2}.#{chrg + 1}")
          output.puts("CHARGE=#{chrg + 1}+")
          output.puts(pepmass)
          output.puts(masses.join("\n"))
          output.puts("END IONS")
        end
        masses = []
        ttl = nil
        chrg = nil
        pepmass = nil
        do_3_charge = false
      when /^\d/
        masses << l
      end
    end
    output.close()
  end
end
if $0 == __FILE__ 

  if ARGV[0] && File.directory?(ARGV[0])
    Dir.chdir(ARGV[0]) unless ARGV[0] == "."
  end
  if ARGV[0] && ARGV[0] =~ /mgf$/
    MGFProcess.post_process(ARGV[0])
  else
    Dir.glob("*.mgf").each do |mgf|
      MGFProcess.post_process(mgf)
    end
  end
end