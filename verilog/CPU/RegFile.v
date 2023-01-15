`include "Register.v"
`include "DeMux1x16.v"

module RegFile(input [3:0] WSEL,
    input W,
    input [15:0] DIN,
    input [3:0] RSEL0,
    input [3:0] RSEL1,
    output [15:0] DOUT0,
    output [15:0] DOUT1);

    wire [15:0] linesW;
    DeMux1x16 WDeMux(W, WSEL, linesW);

    wire [15:0] regDOUTs[15:0];

    Register R0(DIN, linesW[0], regDOUTs[0]);
    Register R1(DIN, linesW[1], regDOUTs[1]);
    Register R2(DIN, linesW[2], regDOUTs[2]);
    Register R3(DIN, linesW[3], regDOUTs[3]);
    Register R4(DIN, linesW[4], regDOUTs[4]);
    Register R5(DIN, linesW[5], regDOUTs[5]);
    Register R6(DIN, linesW[6], regDOUTs[6]);
    Register R7(DIN, linesW[7], regDOUTs[7]);
    Register R8(DIN, linesW[8], regDOUTs[8]);
    Register R9(DIN, linesW[9], regDOUTs[9]);
    Register R10(DIN, linesW[10], regDOUTs[10]);
    Register R11(DIN, linesW[11], regDOUTs[11]);
    Register R12(DIN, linesW[12], regDOUTs[12]);
    Register R13(DIN, linesW[13], regDOUTs[13]);
    Register R14(DIN, linesW[14], regDOUTs[14]);
    Register R15(DIN, linesW[15], regDOUTs[15]);
    
    // Set DOUTs
    wire [15:0] linesRSEL0;
    DeMux1x16 OUT0DeMux(1'b1, RSEL0, linesRSEL0);
    wire [15:0] linesRSEL1;
    DeMux1x16 OUT1DeMux(1'b1, RSEL1, linesRSEL1);

    wire [15:0] DOUT0 = ({16{linesRSEL0[0]}} & regDOUTs[0]) |
                        ({16{linesRSEL0[1]}} & regDOUTs[1]) |
                        ({16{linesRSEL0[2]}} & regDOUTs[2]) |
                        ({16{linesRSEL0[3]}} & regDOUTs[3]) |
                        ({16{linesRSEL0[4]}} & regDOUTs[4]) |
                        ({16{linesRSEL0[5]}} & regDOUTs[5]) |
                        ({16{linesRSEL0[6]}} & regDOUTs[6]) |
                        ({16{linesRSEL0[7]}} & regDOUTs[7]) |
                        ({16{linesRSEL0[8]}} & regDOUTs[8]) |
                        ({16{linesRSEL0[9]}} & regDOUTs[9]) |
                        ({16{linesRSEL0[10]}} & regDOUTs[10]) |
                        ({16{linesRSEL0[11]}} & regDOUTs[11]) |
                        ({16{linesRSEL0[12]}} & regDOUTs[12]) |
                        ({16{linesRSEL0[13]}} & regDOUTs[13]) |
                        ({16{linesRSEL0[14]}} & regDOUTs[14]) |
                        ({16{linesRSEL0[15]}} & regDOUTs[15]);

    wire [15:0] DOUT1 = ({16{linesRSEL1[0]}} & regDOUTs[0]) |
                        ({16{linesRSEL1[1]}} & regDOUTs[1]) |
                        ({16{linesRSEL1[2]}} & regDOUTs[2]) |
                        ({16{linesRSEL1[3]}} & regDOUTs[3]) |
                        ({16{linesRSEL1[4]}} & regDOUTs[4]) |
                        ({16{linesRSEL1[5]}} & regDOUTs[5]) |
                        ({16{linesRSEL1[6]}} & regDOUTs[6]) |
                        ({16{linesRSEL1[7]}} & regDOUTs[7]) |
                        ({16{linesRSEL1[8]}} & regDOUTs[8]) |
                        ({16{linesRSEL1[9]}} & regDOUTs[9]) |
                        ({16{linesRSEL1[10]}} & regDOUTs[10]) |
                        ({16{linesRSEL1[11]}} & regDOUTs[11]) |
                        ({16{linesRSEL1[12]}} & regDOUTs[12]) |
                        ({16{linesRSEL1[13]}} & regDOUTs[13]) |
                        ({16{linesRSEL1[14]}} & regDOUTs[14]) |
                        ({16{linesRSEL1[15]}} & regDOUTs[15]);
endmodule

module RegFile_tests;
    integer STDERR = 32'h80000002;

    reg [3:0] WSEL;
    reg W;
    reg [16:0] DIN;
    reg [3:0] RSEL0;
    reg [3:0] RSEL1;
    wire [15:0] DOUT0;
    wire [15:0] DOUT1;

    RegFile regFile(WSEL, W, DIN[15:0], RSEL0, RSEL1, DOUT0, DOUT1);

    initial begin
        $display("Testing RegFile");

        $display("Testing writing to RegFile");
        for(integer i = 0; i < 2; i++)
            for(integer j = 0; j < 2; j++)
                for(integer register = 0; register < 16; register++) begin
                    testWrite(register[3:0], 0, 2, i, j);
                    testWrite(register[3:0], 1, 2, i, j);
                end

        $display("Testing reading from RegFile");
        testChangingRSEL(16'hffff);
    end

    task outputFailedTest(input [1023:0] testInfo);
        begin
            $fwrite(STDERR, {"Failed test: %s\n",
                "WSEL - %01x\nW - %01x\nDIN - %04x\n",
                "RSEL0 - %01x\nRSEL1 - %01x\n",
                "DOUT0 - %04x\nDOUT1 - %04x\n\n"},
                testInfo, WSEL, W, DIN[15:0], RSEL0, RSEL1,
                DOUT0, DOUT1);
        end
    endtask

    task testWrite(input [3:0] register, input whichRSEL, input [3:0] otherRSEL,
                   input holdWRead, input holdWWrite);
        reg [1023:0] testName;
        integer expDOUT;
        begin
            W = 0;
            #10;
            WSEL = register;
            RSEL0 = whichRSEL ? otherRSEL : register;
            RSEL1 = whichRSEL ? register : otherRSEL;
            #10;
            if(holdWWrite) begin
                DIN = 16'hffff;
                expDOUT = 16'hffff;
                #10;
                W = 1;
                #10;
            end

            for(DIN = 0; DIN < 17'h10000; DIN++) begin
                if(!holdWWrite) begin
                    W = 1;
                    expDOUT = DIN;
                end
                if(holdWRead && holdWWrite)
                    expDOUT = 16'hffff;
                #10;
                W = holdWRead;
                #10;

                if((whichRSEL ? DOUT1 : DOUT0) !== expDOUT) begin
                    $sformat(testName, {"testWrite(register = %04x, whichRSEL = %04x, ",
                        "otherRSEL = %04x, holdWRead = %04x, holdWWrite = %04x), ",
                        "expected %04x"},
                        register, whichRSEL, otherRSEL, holdWRead, holdWWrite, expDOUT);
                   outputFailedTest(testName);
                end

                W = holdWWrite;
                expDOUT = DIN;
                #10;
            end
        end
    endtask

    task testChangingRSEL(input [15:0] iterations);
        reg [1023:0] testInfo;
        reg [15:0][3:0] expectedVals;
        reg [4:0] currReg;
        reg [15:0] expVal;
        begin
            for(integer i = 0; i < iterations; i++) begin
                // Write random values to registers
                for(currReg = 0; currReg < 5'h10; currReg++) begin
                    WSEL = currReg[3:0];
                    expectedVals[currReg[3:0]] = $urandom % 17'h10000;
                    DIN = expectedVals[currReg[3:0]];
                    #10;
                    W = 1;
                    #10;
                    W = 0;
                    RSEL0 = currReg;
                    #10;
                end

                // Test read values from registers
                for(currReg = 0; currReg < 5'h10; currReg++) begin
                    expVal = expectedVals[currReg[3:0]];

                    // Read from DOUT0
                    RSEL0 = currReg[3:0];
                    RSEL1 = $urandom % 5'h10;
                    #10;
                    if(DOUT0 !== expVal) begin
                        $sformat(testInfo,
                            "testChangingRSEL - Read from DOUT0, expected %04x",
                            expVal);
                        outputFailedTest(testInfo);
                    end

                    // Read from DOUT1
                    RSEL0 = $urandom % 5'h10;
                    RSEL1 = currReg[3:0];
                    #10;
                    if(DOUT1 !== expVal) begin
                        $sformat(testInfo,
                            "testChangingRSEL - Read from DOUT1, expected %04x",
                            expVal);
                        outputFailedTest(testInfo);
                    end

                    // Read from same DOUT0 and DOUT1
                    RSEL0 = currReg[3:0];
                    #10;
                    if(DOUT0 !== expVal) begin
                        $sformat(testInfo,
                            {"testChangingRSEL - Read from both DOUT0 and DOUT1, ",
                            "incorrect DOUT0, expected %04x"},
                            expVal);
                        outputFailedTest(testInfo);
                    end
                    if(DOUT1 !== expVal) begin
                         $sformat(testInfo,
                            {"testChangingRSEL - Read from both DOUT0 and DOUT1, ",
                            "incorrect DOUT1, expected %04x"},
                            expVal);
                        outputFailedTest(testInfo);

                    end
                end
            end
        end
    endtask
endmodule
