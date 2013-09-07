##
# True if in debug mode
#
DEBUG = File.open("debug.log", "w")
#DEBUG = STDOUT
#DEBUG = false

##
# Controls debug output for parsing stage
#
DebugParse = true

##
# Runs a block of code without warnings.
#
def silence_warnings(&block)
  original_warn_level = $VERBOSE
  $VERBOSE = nil
  result = block.call
  $VERBOSE = original_warn_level
  result
end

##
# Prevents any debugging if +DEBUG+ is not set
#
unless DEBUG
  silence_warnings {
    # run in silent mode becuase redefinition of constants will cause a warning.
    DebugParse = false
  }
end

module Translator
  
  ##
  # Padding for +debug:parse+ statements
  #
  DebugParsePad = " "*15
  
  ##
  # @api private
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
    "#" => Preprocessor::Methods.method(:comment)
  }
  
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
        if Keychars.has_key? c
          line = Keychars[c].call(line, index)
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
    
    line.chomp!
    begin
      preprocess.()
      
      DEBUG.puts "debug:parse:" + line_num.to_s + ": '" + line + "'" if DebugParse
      parse.()
      DEBUG.puts if DebugParse
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
