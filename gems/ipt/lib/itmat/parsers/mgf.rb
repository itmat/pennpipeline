module ITMAT
  module Parsers
    class MGF < File
      attr_reader :name, :index, :basename
      def initialize(fname) 
        super(fname)
        @name = fname
        @basename = File.basename(fname, ".mgf")
        @index = {}
        self.parse_index()
        @scan_count = @index.size()
      end

      def scan_count 
        @index.size()
      end
      
      def scan(num)
        self.pos = @index[num][:pos]
        Scan.new(self.read( @index[num + 1][:pos] - @index[num][:pos]))
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
        MGF::Scan.new(buff)
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
        t = nil
        scan_num = 0
        self.each do |l|
          case l
          when "BEGIN IONS"
            pos = tmppos
          when /^TITLE=(.+)$/
            @index[scan_num] = {:pos => pos, :title => $1}
            @scan_pos.push(pos)
          end
          tmppos = self.pos
        end
      end
      private :parse_index

      # MGF::Scan 
      # represents an individual scan within the MGF file
      class Scan
        attr_reader :title, :charge, :mz, :intensity, :pepmass
        def initialize(str)
          @title  = nil
          @charge  = nil
          @pepmass  = nil
          @mz = []
          @intensity = []
          str.split("\n").each do |l|
            case l
            when /^TITLE=(.+)/
              @title = $1
            when /^CHARGE=(\d+)/
              @charge = $1.to_i
            when /^PEPMASS=([0-9.]+)/
              @pepmass = $1.to_f
            when /^\d+/
              mz, int =  l.split(/\s/)
              @mz.push( mz.to_f)
              @int.push(int.to_f)
            end
          end
        end
      end
    end
  end
end