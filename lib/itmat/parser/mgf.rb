module ITMAT
  module Parser
    module MGFUtils
      class Mgf < File
        def initialize(fname) 
          super(fname)
          @fname = fname
          @basename = File.basename(fname, ".mgf")
          self.index()
        end
        def index
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
        
        def get_scan(num)
          self.pos = @index[num][:pos]
          Scan.new(self.read( @index[num + 1][:pos] - @index[num][:pos]))
        end

        # Assumes that you are at the begining of a scan! E.g. position before "BEGIN IONS" 
        def next_scan
          buff = ''
          self.each do |l|
            case l 
            when "END IONS"
              break
            else 
              buff << l
            end
          end
          Scan.new(buff)
        end
      end
      
      class Scan
        attr :title, :charge, :mz, :pepmass
        def initialize(str)
          @title  = nil
          @charge  = nil
          @pepmass  = nil
          @mz = []
          @int= []
          self.parse(str)
        end
        private
        def parse(str)
          str.split("\n").each do |l|
            case l
            when /^TITLE=(.+)$/
              @title = $1
            when /^CHARGE=(.+)$/
              @charge = $1.to_i
            when /^PEPMASS=(.+)$/
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