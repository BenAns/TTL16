`include "ALU.v"
`include "RegFile.v"
`include "PC.v"
`include "Microcode.v"
`include "MicrocodeCounter.v"

module CPU(input CLK,
    input RST,
    input IRQ,
    input [3:0] IC,
    output [15:0] A,
    output W,
    inout wire [15:0] D);

    // ALU
    wire [15:0] aALU, bALU, qALU;
    wire [4:0] opALU;
    wire overflowALU, lessALU, equalALU, greaterALU, zeroALU;
    ALU ALUUnit(aALU, bALU, opALU, qALU, overflowALU, lessALU,
                equalALU, greaterALU, zeroALU);

    // Register file
    wire [3:0] wselRegFile, rsel0RegFile, rsel1RegFile;
    wire wRegFile;
    wire [15:0] dinRegFile, dout0RegFile, dout1RegFile;
    assign dinRegFile[15:0] = D[15:0];
    RegFile registers(wselRegFile, wRegFile, dinRegFile, rsel0RegFile,
                      rsel1RegFile, dout0RegFile, dout1RegFile);

    // PC
    wire [15:0] dinPC, doutPC;
    wire PCW, writeFromDIN;
    assign dinPC[15:0] = D[15:0];
    PC PCUnit(dinPC, PCW, writeFromDIN, doutPC);

    // Instruction register
    wire [15:0] dinInstr, doutInstr;
    wire wInstr;
    assign dinInstr[15:0] = D[15:0];
    Register InstrReg(dinInstr, wInstr, doutInstr);

    // Flags register
    wire [15:0] dinFlags, doutFlags;
    assign dinFlags[15:0] = {11'h000, zeroALU, lessALU, equalALU, greaterALU, overflowALU};
    wire wFlags;
    Register flagsReg(dinFlags, wFlags, doutFlags);

    // Microcode counter
    wire counterRST;
    wire [3:0] counterVal;
    MicrocodeCounter MCCont(CLK, counterRST, counterVal);
    
    // Microcode
    wire PCToA, ALUToD, shiftInstrToD, rsel0ToA, rsel1ToD, enableInterrupts;
    Microcode MC(counterVal, doutInstr, doutFlags[4:0], counterRST, PCToA, PCW, writeFromDIN,
                 wInstr, ALUToD, rsel0RegFile[3:0], rsel1RegFile[3:0], wselRegFile[3:0],
                 wRegFile, shiftInstrToD, wFlags, rsel0ToA, rsel1ToD, W, enableInterrupts);

    // Address bus
    assign A[15:0] = PCToA ? doutPC[15:0] :
                     rsel0ToA ? dout0RegFile[15:0] : 16'bzzzzzzzzzzzzzzzz;
    
    // Data bus
    assign D[15:0] = ALUToD ? qALU[15:0] :
                     shiftInstrToD ? {5'h00, doutInstr[14:4]} :
                     rsel1ToD ? dout1RegFile[15:0] : 16'bzzzzzzzzzzzzzzzz;
endmodule
