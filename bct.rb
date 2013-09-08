##
# Output streams
#
OUT = File.open("prog.bc", "w")
DEBUG = File.open("prog.debug", "w")
#DEBUG = STDOUT

##
# Controls debug output for parsing stage
#
DebugParse = false

##
# Controls debug output for encoding stage
#
DebugEncode = true

module Translator
  
  ##
  # Padding for +debug:parse+ statements
  #
  DebugParsePad = "#"+" "*16
  
  ##
  # Padding for +debug:encode+ statements
  #
  DebugEncodePad = "#"+" "*17
  
  ##
  # Holds resources for preprocessing
  #
  module Preprocessor
    class Methods
      ##
      # Strips out comments.
      # @param line [String]
      # @param pos [Fixnum] the position of the start of the comment in +line+
      # @return [String] the resulting line
      def self.comment(line, pos)
        line[0, pos]
      end
    end
    
    ##
    # A +Hash<String, Method<String, Fixnum>>+ of key characters to be processed
    #   before parsing.
    #
    # Keys should be single character +String+s.
    #
    # In the preprocess step, the line will be scanned for keys in +Keychars+.
    # Upon locating one, the preprocessor will call the corresponding +Method+
    #   for the key, passing in a +String+ representing the line,
    #   and a +Fixnum+ representing the location at which the key was found.
    #
    Keychars = {
      "#" => Methods.method(:comment)
    }
    
  end
  
  module Encoder
    
    ##
    # A +Hash<String, String>+ of instruction names to be mapped to their
    #   associated +bc+ values.
    #
    Keywords = {
      "stor" => 0x01,
      "mult" => 0x13,
      "debug"=> 0x60
    }
    
  end
  
  ##
  # Translates a single line of +bc+.
  #
  def self.translate(line, line_num = nil)
    
    ##
    # Strips out comments.
    #
    preprocess = lambda do
      index = 0
      line.each_char do |c|
        if Preprocessor::Keychars.has_key? c
          line = Preprocessor::Keychars[c].call(line, index)
        end
        index += 1
      end
    end
    
    ##
    # Splits up the line into tokens, then resolves them into raw data and
    #   +bc+ instructions.
    #
    parse = lambda do
      DEBUG.puts DebugParsePad + "Split '#{line}'" if DebugParse
      line = line.split
      DEBUG.puts DebugParsePad + "Result: " + line.inspect if DebugParse
      DEBUG.puts DebugParsePad + "Resolve register names" if DebugParse
      (1..line.length-1).each do |i|
        if line.length > 1 and line[i][0] == "r"
          line[i] = Integer(line[i][1..-1])
        end
      end
      DEBUG.puts DebugParsePad + "Result: " + line.inspect if DebugParse
      DEBUG.puts DebugParsePad + "Resolve integer literals" if DebugParse
      (1..line.length-1).each do |i|
        line[i] = Integer(line[i])
      end
      DEBUG.puts DebugParsePad + "Result: " + line.inspect if DebugParse
    end
    
    encode = lambda do
      for tok in line
        if tok.class == Fixnum
          OUT.print tok.chr
          DEBUG.print "0x%02x " % tok if DebugEncode
        elsif tok.class == String
          OUT.print Encoder::Keywords[tok].chr
          DEBUG.print "0x%02x " % Encoder::Keywords[tok] if DebugEncode
        end
      end
    end
    
    line.chomp!
    begin
      preprocess.()
      
      DEBUG.puts "# debug:parse:" + line_num.to_s + ": '" + line + "'" if DebugParse
      parse.()
      DEBUG.puts if DebugParse
      
      #DEBUG.puts "# debug:encode:" + line_num.to_s + ": #{line.inspect}" if DebugEncode
      encode.()
      1.times {DEBUG.puts} if DebugEncode and line.length > 0
    end
  end
end

##
# Program driver.
#
if __FILE__ == $0
  iter = 0
  ARGF.each_line do |line|
    Translator.translate(line, iter+=1)
  end
end
