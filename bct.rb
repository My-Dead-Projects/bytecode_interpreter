OUT = File.open("prog.bc", "w")

module Translator
  
  module Preprocessor
    
    class Methods
      
      def self.comment(line, pos)
        line[0, pos]
      end
    end
    
    Keychars = {
      "#" => Methods.method(:comment)
    }
  end
  
  module Encoder
    
    Keywords = {
      "stor" => 0x01,
      "mult" => 0x13,
      "debug"=> 0x60
    }
  end
  
  def self.translate(line, line_num = nil)
    
    preprocess = lambda do
      index = 0
      line.each_char do |c|
        if Preprocessor::Keychars.has_key? c
          line = Preprocessor::Keychars[c].call(line, index)
        end
        index += 1
      end
    end
    
    parse = lambda do
      line = line.split
      (1..line.length-1).each do |i|
        if line.length > 1 and line[i][0] == "r"
          line[i] = Integer(line[i][1..-1])
        end
      end
      (1..line.length-1).each do |i|
        line[i] = Integer(line[i])
      end
    end
    
    encode = lambda do
      for tok in line
        if tok.class == Fixnum
          OUT.print tok.chr
        elsif tok.class == String
          OUT.print Encoder::Keywords[tok].chr
        end
      end
    end
    
    line.chomp!
    begin
      preprocess.()
      
      parse.()
      
      encode.()
    end
  end
end

if __FILE__ == $0
  iter = 0
  ARGF.each_line do |line|
    Translator.translate(line, iter+=1)
  end
end
