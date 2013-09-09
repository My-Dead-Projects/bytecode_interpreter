module Runtime
  
  module VM
    @reg = [].fill(0, 0..15)
    def self.reg
      @reg
    end
    def self.reg=(r)
      @reg = r
    end
    
  end
  
  module Code
    def self.store(arg)
      RT::VM.reg[arg[0]] = arg[1]
    end
    
    def self.debug(arg)
      p RT::VM.reg[arg[0]]
    end
    
    def self.multiply(arg)
      RT::VM.reg[arg[0]] = RT::VM.reg[arg[0]] * RT::VM.reg[arg[1]]
    end
  end
  
  Struct.new "Instruction", :code, :args
  
  InstrCode = {
  0x01 => Struct::Instruction.new(Code.method(:store), 2),
  0x13 => Struct::Instruction.new(Code.method(:multiply), 2),
  0x60 => Struct::Instruction.new(Code.method(:debug), 1)
  }
  
end

RT = Runtime

module Interpreter
  
  @instr = nil
  @args = []
  
  def self.interpret(byte)
    if @instr == nil
      @instr = RT::InstrCode[byte]
    else
      @args.push byte
    end
    
    if @instr.args == @args.length
      @instr.code.call(@args)
      
      @instr = nil
      @args = []
    end
  end
end

if __FILE__ == $0
  ARGF.each_byte do |byte|
    Interpreter.interpret(byte)
  end
end
