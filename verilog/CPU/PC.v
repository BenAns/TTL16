`include "Register.v"

module PC(input [15:0] DIN,
          input W,
          input writeFromDIN,
          output [15:0] DOUT);

    wire [15:0] incPC = DOUT + 1;
    wire [15:0] regInput = ({16{writeFromDIN}} & DIN) |
                           ({16{~writeFromDIN}} & incPC);
    Register regPC(regInput, W, DOUT);
endmodule

module PC_tests;
    integer STDERR = 32'h80000002;

    reg [15:0] DIN;
    reg W;
    reg writeFromDIN;
    wire [15:0] DOUT;

    PC unitPC(DIN, W, writeFromDIN, DOUT);

    initial begin
        $display("Starting PC tests");

        $display("Testing incrementing PC");
        for(integer i = 0; i < 4; i++)
            incrementPC(i[1], i[0]);

        $display("Testing writing directly to PC");
        for(integer i = 0; i < 4; i++)
            writeDINtoPC(i[1], i[0]);
    end

    task outputFailedTest(input [1023:0] testInfo);
        begin
            $fwrite(STDERR, {"Failed test: %s\n",
                "DIN - %04x\nW - %01x\nwriteFromDIN - %01x\n",
                "DOUT - %04x\n\n"},
                testInfo, DIN, W, writeFromDIN, DOUT);
        end
    endtask

    task incrementPC(input holdWWrite, input holdWRead);
        reg [1023:0] testInfo;
        reg [15:0] expVal;
        begin
            // Initialise PC to 0xFFFF
            DIN = 16'hFFFF;
            writeFromDIN = 1;
            W = 0;
            #10;
            W = 1;
            #10;
            W = holdWWrite;
            #10;
            writeFromDIN = 0;
            #10;
            expVal = holdWWrite && !holdWRead ? 16'hFFFF : 16'hFFFF;

            // Incrementing until 0xFFFF
            for(integer i = 0; i < 17'h10000; i++) begin
                W = 1;
                if(!holdWWrite)
                    expVal++;
                #10;
                W = holdWRead;
                #10;

                if(DOUT !== expVal) begin
                    $sformat(testInfo, {"incrementPC(holdWWrite - %01x, ",
                        "holdWRead - %01x), expected DOUT = %04x"},
                        holdWWrite, holdWRead, expVal);
                    outputFailedTest(testInfo);
                end
                
                W = holdWWrite;
                if(holdWWrite && !holdWRead)
                    expVal++;
                #10;
            end
        end
    endtask

    task writeDINtoPC(input holdWWrite, input holdWRead);
        reg [1023:0] testInfo;
        reg [15:0] expVal;
        begin
            writeFromDIN = 1;
            #10;
            W = 1;
            #10;
            W = holdWWrite;
            #10;
            expVal = DOUT;

            for(integer i = 0; i < 17'h10000; i++) begin
                DIN = i[15:0];
                #10;
                W = 1;
                if(!holdWWrite)
                    expVal = i;
                #10;
                W = holdWRead;
                #10;

                if(DOUT !== expVal) begin
                    $sformat(testInfo, {"writeDINtoPC(holdWWrite - %01x, ",
                        "holdWRead - %01x), expected DOUT = %04x"},
                        holdWWrite, holdWRead, expVal);
                    outputFailedTest(testInfo);
                end
                
                W = holdWWrite;
                if(holdWWrite && !holdWRead)
                    expVal = i;
                #10;
            end
        end
    endtask
endmodule
