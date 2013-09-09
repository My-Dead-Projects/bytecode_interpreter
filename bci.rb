##
# True if in debug mode
#
DEBUG = File.open("exec.debug", "w")
#DEBUG = STDOUT
#DEBUG = false

##
# Controls debug output for executing stage
#
DebugExec = true

##
# Padding for +debug:exec+ statements
#
DebugExecPad = " "*14

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
  module Code
    ##
    # Stores +val+ in +reg+.
    # @param reg [Fixnum]
    # @param val
    #
    def self.store(arg)
      DEBUG.puts DebugExecPad + "Storing #{arg[0]} in r#{arg[1]}" if DebugExec
      RT::VM.reg[arg[0]] = arg[1]
    end
    
    ##
    # Prints the value of register +reg+.
    # @param reg [Fixnum]
    #
    def self.debug(arg)
      p RT::VM.reg[arg[0]]
    end
    
    ##
    # Multiplies +lhr+ by +rhr+ and stores the result in +lhr+.
    # @param lhr [Fixnum]
    # @param rhr [Fixnum]
    #
    def self.multiply(arg)
      DEBUG.puts DebugExecPad + "Multiplying r#{arg[0]} (#{RT::VM.reg[arg[0]]}) x r#{arg[1]} (#{RT::VM.reg[arg[1]]})" if DebugExec
      RT::VM.reg[arg[0]] = RT::VM.reg[arg[0]] * RT::VM.reg[arg[1]]
      DEBUG.puts DebugExecPad + "Result stored in r#{arg[0]} (#{RT::VM.reg[arg[0]]})" if DebugExec
    end
  end
  
  Struct.new "Instruction", :code, :args
  
  InstrCode = {
  0x01 => Struct::Instruction.new(Code.method(:store), 2),
  0x13 => Struct::Instruction.new(Code.method(:multiply), 2),
  0x60 => Struct::Instruction.new(Code.method(:debug), 1)
  }
  
end

##
# Alias of +Runtime+
#
RT = Runtime

module Interpreter
  
  @insgr_code = nil if DebugExec
  
  @instr = nil
  @args = []
  
  ##
  # Interprets a single line of +bc+.
  #
  def self.interpret(byte)
    
    if @instr == nil
      @instr = RT::InstrCode[byte]
      @instr_code = byte if DebugExec
    else
      @args.push byte
    end
    
    if @instr.args == @args.length
      if DebugExec
        DEBUG.print "debug:exec: 0x%02x " % @instr_code
        for arg in @args
          DEBUG.print "0x%02x " % arg
        end
        DEBUG.puts
      end
      @instr.code.call(@args)
      
      @instr = nil
      @args = []
      
    end
    
  end
end

##
# Program driver.
#
if __FILE__ == $0
  ARGF.each_byte do |byte|
    Interpreter.interpret(byte)
  end
end
