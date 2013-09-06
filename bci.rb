##
# True if in debug mode
#
DEBUG = File.open("debug.log", "w")
#DEBUG = STDOUT
#DEBUG = false

##
# Controls debug output for parsing stage
#
DebugParse = false

##
# Controls debug output for executing stage
#
DebugExec = true

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
    DebugParse = DebugExec = false
  }
end

##
# Maintains the virtual machine which runs the bytecode.
#
module Runtime
  
  ##
  # The virtual machine which runs the bytecode.
  #
  module VM
    @reg = [].fill(0, 0..15)
    def self.reg
      @reg
    end
    def self.reg=(r)
      @reg = r
    end
    
  end
  
  ##
  # Contains methods corresponding to +bc+ instructions.
  #
  module Instruction
    ##
    # Stores +val+ in +reg+.
    # @param reg [Fixnum]
    # @param val
    #
    def self.stor(reg, val)
      Runtime::VM.reg[reg] = val
    end
    
    ##
    # Prints the value of register +reg+.
    # @param reg [Fixnum]
    #
    def self.debug(reg)
      p Runtime::VM.reg[reg]
    end
    
    ##
    # Multiplies +lhr+ by +rhr+ and stores the result in +lhr+.
    # @param lhr [Fixnum]
    # @param rhr [Fixnum]
    #
    def self.mult(lhr, rhr)
      Runtime::VM.reg[lhr] = Runtime::VM.reg[lhr] * Runtime::VM.reg[rhr]
    end
  end
  
end

##
# Alias of +Runtime+
#
RT = Runtime

module Interpreter
  
  ##
  # Padding for +debug:parse+ statements
  #
  DebugParsePad = " "*15
  
  ##
  # Padding for +debug:exec+ statements
  #
  DebugExecPad = " "*14
  
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
  # Interprets a single line of +bc+.
  #
  def self.interpret(line, line_num = nil)
    
    ##
    # So far, just strips out comments.
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
    # Splits up the line into tokens, then resolves them into data that the
    #   VM can use.
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
      if line.length == 3 and line[2] =~ /[0-9]+/
        line[2] = Integer(line[2])
      end
      DEBUG.puts DebugParsePad + "Result: " + line.inspect if DebugParse
    end
    
    ##
    # Executes a single preprocessed, parsed line.
    #
    exec = lambda do
      if line.length > 3
        raise StandardError, "Too many arguments for #{line[0]}"
      elsif line.length == 3
        Runtime::Instruction.method(line[0].to_sym).call(line[1], line[2])
      elsif line.length == 2
        Runtime::Instruction.method(line[0].to_sym).call(line[1])
      elsif line.length == 1
        Runtime::Instruction.method(line[0].to_sym).call
      end
    end
    
    line.chomp!
    begin
      preprocess.()
      
      DEBUG.puts "debug:parse:" + line_num.to_s + ": '" + line + "'" if DebugParse
      parse.()
      DEBUG.puts if DebugParse
      
      DEBUG.puts "debug:exec:" + line_num.to_s + ": " + line.inspect if DebugExec
      exec.()
      DEBUG.puts if DebugExec
    end
  end
end

##
# Program driver.
#
if __FILE__ == $0
  iter = 0
  ARGF.each_line do |line|
    Interpreter.interpret(line, iter+=1)
  end
end
