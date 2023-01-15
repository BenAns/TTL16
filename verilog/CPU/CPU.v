`include "ALU.v"
`include "RegFile.v"
`include "PC.v"

module CPU(input CLK,
    input RST,
    input IRQ,
    input [3:0] IC,
    output [15:0] A,
    wire [15:0] D);

    wire [15:0] aALU, bALU, qALU;
    wire [4:0] opALU;
    wire overflowALU, lessALU, equalALU, greaterALU, zeroALU;
    ALU ALUUnit(aALU, bALU, opALU, qALU, overflowALU, lessALU,
                equalALU, greaterALU, zeroALU);

    wire [3:0] wselRegFile, rsel0RegFile, rsel1RegFile;
    wire wRegFile;
    wire [15:0] dinRegFile, dout0RegFile, dout1RegFile;
    RegFile registers(wselRegFile, wRegFile, dinRegFile, rsel0RegFile,
                      rsel1RegFile, dout0RegFile, dout1RegFile);

    wire [15:0] dinPC, doutPC;
    wire W, writeFromDIN;
    PC PCUnit(dinPC, W, writeFromDIN, doutPC);
endmodule
