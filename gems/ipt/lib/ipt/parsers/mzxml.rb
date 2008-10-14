module IPT
  module Parsers
    class MzXML < File
      require 'hpricot'
      require 'base64'
      require 'zlib'
      @@BYTEORDER = {"little" =>"e*", "network"=>"g*", "big"=>"g*"}

      def initialize (fname )
        super(fname, "r")
        self.readline
        if (self.readline =~  /mzData/) then
          @isMzData = true
        else 
          @isMzData = false
        end
        @offset = parse_index_offset
        @index = parse_index
        @header = parse_header
        @basepeak = nil
        self.pos = 0
      end
      
      # Boolean determining whether the opened file is an mzData file, rather than mzXML
      attr_reader :isMzData
      # The scan index read (or computed) from the mzXML/mzData file. A Hash of {scanNum => file_position}
      #-- 
      # should work on both file types
      attr_reader :index
      # The mzXML/mzData header annotations (should have some useful information in it ;-) ) as REXML::Element
      attr_reader :header
      # The base peak chromatograph (*WARNING* Calculated the first time it is accessed, which may take a bit of time)
      attr_reader :basePeak

      private
      # Parses the indexOffset from mzXML files 
      def parse_index_offset
        return -1 if @isMzData
        r = %r{\<indexOffset\>(\d+)\<\/indexOffset\>}
        seekoffset = -120
        while true 
          self.seek(seekoffset, IO::SEEK_END)
          if (r.match(self.read)) then 
            return  $1.to_i
          end
          seekoffset -= 10
          return -1 if seekoffset <= -1000
        end
      end
      
      # Return a hash of scans, where {scan number} = file offset
      def parse_index
        if (@offset < 0) then 
          return compute_index
        end
        r= %r{\<offset\s+id=\"(\d+)\"\s*\>(\d+)\<\/offset\>}
        self.pos = @offset
        index = {}
        while (!self.eof?) 
          next unless (r.match(self.readline))
          index[$1.to_i] = $2.to_i
        end
        ## now check the index, otherwise recompute it!!!
        # beginning
        r =/\<scan|\<spectrum\sid/
        tmpkeys = index.keys.sort
        self.pos = index[tmpkeys.first]
        if (!(self.readline =~ r ))
          index = compute_index
        else
          #middle 
          self.pos = index[tmpkeys[tmpkeys.length()/2]]
          if (!(self.readline =~ r))
            index = compute_index
          else
            #end
            self.pos = index[tmpkeys.last]
            if (!(self.readline =~ r))
              index = compute_index
            end
          end
        end
        #return the index
        index
      end

      # Parses the file header information
      def parse_header
        self.pos = 0
        r = %r{\<scan\s|\<spectrum\s}
        xml = "" 
        while true
          l = self.readline
          break if l =~ r
          xml << l 
        end
        if (@isMzData) then 
          xml << "</spectrumList></mzData>"
        else 
          xml << "</msRun></mzXML>"
        end
        # return a REXML::Element unless XML is empty => nil
        xml.empty? ? nil : self.parse(xml)
      end

      # Computes the index by scanning the entire file
      def compute_index 
        self.rewind
        r = %r{\<scan\snum\=\"(\d+)\"|\<spectrum\sid\=\"(\d+)\"}
        index  = {}
        while (!self.eof) 
          pos = self.pos
          if (r.match(self.readline)) then 
            m = $1 ? $1 : $2
            index[m.to_i] = pos
          end
        end
        index
      end
      # parses a bit of XML into a REXML::Element node
      protected

      def parse(xml) # :nodoc:
        # REXML::Document.new(xml).root()
        Hpricot.XML(xml).root
      end

      def parse_base_peak #:nodoc: all
        self.pos = 0
        @basepeak = [[],[]]
        if (@isMzData) 
          # MUCH more expensive to compute
          while (s = self.next_scan)
            p = self.get_peaks(s)
            max_int = -1.0
            bp_idx = 0
            p[1].each_index do |i|
              bp_idx = i if p[1][i] > max_int
            end
            @basepeak[0].push(p[0][bp_idx]) 
            @basepeak[0].push(p[1][bp_idx]) 
          end
        else
          numr= %r{\<scan num\=[\"|\'](\d+)[\"|\']}
          bpr= %r{basePeak(\w+)\=[\"|\'](\S+)[\"|\']}
          num = 0
          while(!self.eof?)
            l = self.readline
            if (m = numr.match(l))
              num = m[1].to_i
              next
            end
            if (m = bpr.match(l))
              if m[1] == "Mz"
                @basepeak[0].push(num) 
              else
                @basepeak[1].push(m[2].to_f)  
              end
            end
          end
        end
        @basepeak
      end

      def get_scan_from_curr_pos #:nodoc:
        return nil if (self.eof)
        xml = ""
        while (!self.eof )
          l = self.readline
          if (l =~ /\<\/scan\>|\<\/spectrum\>/) then
            xml.concat(l)
            break 
          end
          xml.concat(l)
        end
        xml.empty? ? nil :  self.parse(xml)
      end

      public 
      # Return a REXML::Element node for a given scan
      # 
      # * scanNum =  the scan number
      def scan scanNum
        self.pos = @index[scanNum]
        get_scan_from_curr_pos
      end

      # Return a REXML::Element node for the next scan sequentially encountered with respect to the file. 
      # This may not correspond to any notion of scan ordering by ms_level, retention time, etc., it is 
      # simply related to file read position. 
      #
      # This method pays no attention to the last scan called in your routines. If you made any other API 
      # calls that change the file read position (most methods do), the result will be unexpected. Use at your own risk  :-P

      def next_scan 
        lastPos = self.pos
        while (!self.eof )
          l = self.readline
          break if l =~ /\<scan|\<spectrum\s/
          lastPos = self.pos
        end
        self.pos = lastPos
        get_scan_from_curr_pos
      end

      # Parse the mz and intensity (e.g. peaks) from the particular scan object
      # * scan = retrieved from get_scan 
      # * retuns an Array of mz and intensity Arrays (e.g. [ [mz], [int] ])
      def get_peaks scan
        return nil unless scan 
        scan.to_s =~ /\<peaks\s.*\>(\w+)\<\/peaks\>/
        return $1

        pks = [[],[]]; 
        if (!@isMzData) then 
          pkelm = scan.at('peaks')
          sym = @@BYTEORDER[pkelm[:byteorder]]
          sym.upcase! if (pkelm[:precision].to_i > 32)
          data = Base64.decode64(pkelm.inner_text())
          if (pkelm[:compressiontype] == 'zlib')
            data = Zlib::Inflate.inflate(data)
          end
          tmp = data.unpack("#{sym}")
          tmp.each_index do |idx|
            if (idx % 2 == 0 ) then 
              pks[0].push(tmp[idx])
            else
              pks[1].push(tmp[idx])
            end
          end
        else
          # first, get mz array data
          tmp = scan.search('mzArrayBinary/data')
          sym = @@BYTEORDER[tmp.attr('endian')]
          sym.upcase! if (tmp.attr('precision').to_i > 32)
          pks[0] = Base64.decode64(tmp.text()).unpack(sym)
          # mz = Base64.decode64(tmp.text).unpack(sym)
          #now for the intensity array
          tmp = scan.search('intenArrayBinary/data')
          sym = @@BYTEORDER[tmp.attr('endian')]
          sym.upcase! if (tmp.attr('precision').to_i > 32)
          pks[1] = Base64.decode64(tmp.text()).unpack(sym)
          # int = Base64.decode64(tmp.text).unpack(sym)
        end
        pks
      end
      def basePeak #:nodoc: all
        return @basepeak if @basepeak
        self.parse_base_peak
      end
    end
  end
end
