`ifndef REGISTER_V
`define REGISTER_V

module Register(input [15:0] DIN,
    input W,
    output [15:0] DOUT);

    // Set/clear latches
    wire [15:0] set;
    wire [15:0] notSet;
    wire [15:0] clear;
    wire [15:0] notClear;
    assign set[15:0] = ~(clear & notSet);
    assign notSet[15:0] = ~({16{W}} & set);
    assign clear[15:0] = ~(DIN & notClear);
    assign notClear[15:0] = ~(notSet & {16{W}} & clear);

    // Output latch
    wire [15:0] notDOUT = ~(DOUT & notClear);
    wire [15:0] DOUT = ~(notDOUT & notSet);
endmodule

module Register_tests;
    integer STDERR = 32'h80000002;

    reg [16:0] DIN;
    reg W;

    wire [15:0] DOUT;

    Register testReg(DIN[15:0], W,DOUT);

    initial begin
        $display("Starting register tests");
        $display("Testing writing new values to register");
        writeVals(0);
        writeVals(1);

        $display("Testing retaining values from register");
        holdVals();
    end

    task outputFailedTest(input [511:0] testInfo);
        begin
            $fwrite(STDERR, {"Failed test: %s\n",
                "DIN - %04x\nW - %x\n",
                "DOUT - %04x\n\n"},
                testInfo, DIN[15:0], W, DOUT);
        end
    endtask

    task writeVals(input holdWRead);
        reg [511:0] testInfo;
        begin
            $sformat(testInfo, "writeVals(holdWRead = %01x)", holdWRead);
            W = 0;
            #10;

            for(DIN = 0; DIN < 17'h10000; DIN++) begin
                #10;
                W = 1;
                #10;
                W = holdWRead;
                #10;

                if(DIN[15:0] !== DOUT[15:0])
                    outputFailedTest(testInfo);
                W = 0;
                #10;
            end
        end
    endtask

    task holdVals;
        begin
            DIN = 16'haaaa;
            #10;
            W = 1;
            #10;
            if(DOUT !== 16'haaaa)
                outputFailedTest("holdVals - Value not initially written");

            W = 0;
            #10;
            if(DOUT !== 16'haaaa)
                outputFailedTest("holdVals - Value changed after negative clock edge");
            
            DIN = 16'h0000;
            #10;
            if(DOUT !== 16'haaaa)
                outputFailedTest("holdVals - Value changed after DIN change with W = 0");

            DIN = 16'haaaa;
            #10;
            W = 1;
            #10;
            DIN = 16'h0000;
            #10;
            if(DOUT != 16'haaaa)
                outputFailedTest("holdVals - Values changed after DIN change with W = 1");
        end
    endtask
endmodule

`endif
