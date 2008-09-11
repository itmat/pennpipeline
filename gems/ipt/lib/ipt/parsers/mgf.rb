module IPT
  module Parsers
    class MGF < File
      attr_reader :name, :index, :basename
      def initialize(fname) 
        super(fname)
        @name = fname
        @basename = File.basename(fname, ".mgf")
        @index = {}
        parse_index()
      end

      def scan_count 
        @index.size()
      end
      
      def scan(num)
        num = num.to_i
	self.pos = @index[num.to_s][:pos].to_i
	if (num>=self.scan_count-1)
	  #read to the end
          return Scan.new(self.read())
        else
          return Scan.new(self.read( @index[(num + 1).to_s][:pos].to_i - @index[num.to_s][:pos].to_i))
	end
      end

      # Assumes that you are at the begining of a scan! E.g. position before "BEGIN IONS" 
      def next_scan
        return nil if self.eof?
        buff = ''
        while(!self.eof?) 
          l = self.readline
          break if l =~  /END IONS/
          buff << l
        end
        return Scan.new(buff)
      end
      
      def each_scan 
        self.rewind()
        while !self.eof?
          yield self.next_scan()
        end
      end
      
      def parse_index()
        @index = Hash.new()
        @scan_pos = []
        self.pos = 0
        tmppos = self.pos 
        pos = nil
        scan_num = 0
        self.each do |l|
          case l
          when /^BEGIN IONS/
            pos = tmppos
          when /^TITLE=(.+)$/
            @index[scan_num.to_s] = {:pos => pos,:title => $1}
            @scan_pos.push(pos)
            scan_num+=1
          end
          tmppos = self.pos
        end
      end
      private :parse_index

      # MGF::Scan 
      # represents an individual scan within the MGF file
      class Scan
        attr_reader :title, :charge, :mz, :intensity, :pepmass, :input
        def initialize(str)
          @input = str #debug purposes
          @title  = nil
          @charge  = nil
          @pepmass  = nil
          @mz = []
          @intensity = []
          str.split("\n").each do |l|
            case l
            when /^TITLE=(.+)/
              @title = $1.chomp!
            when /^CHARGE=(\d+)/
              @charge = $1.to_i
            when /^PEPMASS=([0-9.]+)/
              @pepmass = $1.to_f
            when /^\d+/
              mz, int =  l.split(/\s/)
              @mz.push( mz.to_f)
              @intensity.push(int.to_f)
            end
          end
        end
      end
    end
  end
end