module Register(input [15:0] DIN,
    input W,
    input RE,
    output [15:0] DOUT);

   wire [15:0] regVal = (DIN & {16{W}}) | (regVal & {16{!W}});
   wire [15:0] DOUT = RE ? {16{1'bZ}}  : regVal;
endmodule

module Register_tests;
    integer STDERR = 32'h80000002;

    reg [16:0] DIN;
    reg W;
    reg RE;

    wire [15:0] DOUT;

    Register testReg(DIN[15:0], W, RE, DOUT);

    initial begin
        $display("Starting register tests");

        $display("Testing setting values");
        writeValsWithSetW();
        writeValsChangedSetW();
        writeValsHeldSetW();

        $display("Testing enabling/disabling reading values");
        noOutWithSetRE();
    end

    task outputFailedTest(input [255:0] testInfo);
        begin
            $fwrite(STDERR, {"Failed test: %s\n",
                "DIN - %04x\nW - %x\nRE - %x\n",
                "DOUT - %04x\n\n"},
                testInfo, DIN[15:0], W, RE, DOUT);
        end
    endtask

    task writeValsWithSetW;
        begin
            W = 1;
            RE = 0;
            #10;

            for(DIN = 0; DIN < 17'h10000; DIN++) begin
                #10;
                if(DIN[15:0] !== DOUT[15:0])
                    outputFailedTest("Write values with constant set W");
            end
        end
    endtask

    task writeValsChangedSetW;
        begin
            W = 1;
            RE = 0;
            #10;

            for(DIN = 0; DIN < 17'h10000; DIN++) begin
                #10;
                W = 0;
                #10;
                if(DIN[15:0] !== DOUT[15:0])
                    outputFailedTest("Write values changed while set W");
                W = 1;
                #10;
            end
        end
    endtask

    task writeValsHeldSetW;
        begin
            W = 0;
            RE = 0;
            #10;

            for(DIN = 0; DIN < 17'h10000; DIN++) begin
                #10;
                W = 1;
                #10;
                W = 0;
                #10;
                if(DIN[15:0] !== DOUT[15:0])
                    outputFailedTest("Write values held while set W");
            end
        end
    endtask

    task noOutWithSetRE;
        begin
            RE = 1;
            #10;

            for(DIN = 0; DIN < 17'h10000; DIN++) begin
                #10;
                W = 1;
                #10;
                if(DOUT[15:0] !== {16{1'bZ}})
                    outputFailedTest("No output with set RE");
                W = 0;
                #10;
                if(DOUT[15:0] !== {16{1'bZ}})
                    outputFailedTest("No output with set RE");
            end
        end
    endtask
endmodule
