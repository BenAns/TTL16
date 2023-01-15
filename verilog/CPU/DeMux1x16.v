module DeMux1x16(input DIN,
    input [3:0] S,
    output [15:0] Q);
    
    assign Q[0] = DIN & ~S[3] & ~S[2] & ~S[1] & ~S[0];
    assign Q[1] = DIN & ~S[3] & ~S[2] & ~S[1] & S[0];
    assign Q[2] = DIN & ~S[3] & ~S[2] & S[1] & ~S[0];
    assign Q[3] = DIN & ~S[3] & ~S[2] & S[1] & S[0];
    assign Q[4] = DIN & ~S[3] & S[2] & ~S[1] & ~S[0];
    assign Q[5] = DIN & ~S[3] & S[2] & ~S[1] & S[0];
    assign Q[6] = DIN & ~S[3] & S[2] & S[1] & ~S[0];
    assign Q[7] = DIN & ~S[3] & S[2] & S[1] & S[0];
    assign Q[8] = DIN & S[3] & ~S[2] & ~S[1] & ~S[0];
    assign Q[9] = DIN & S[3] & ~S[2] & ~S[1] & S[0];
    assign Q[10] = DIN & S[3] & ~S[2] & S[1] & ~S[0];
    assign Q[11] = DIN & S[3] & ~S[2] & S[1] & S[0];
    assign Q[12] = DIN & S[3] & S[2] & ~S[1] & ~S[0];
    assign Q[13] = DIN & S[3] & S[2] & ~S[1] & S[0];
    assign Q[14] = DIN & S[3] & S[2] & S[1] & ~S[0];
    assign Q[15] = DIN & S[3] & S[2] & S[1] & S[0];
endmodule

module DeMux1x16_tests;
	integer STDERR = 32'h80000002;

    reg DIN;
    reg [4:0] S;
    wire [15:0] Q;

    DeMux1x16 demux(DIN, S[3:0], Q);

    reg [15:0] Qzeroed;

    initial begin
        $display("Testing DeMux1x16");

        DIN = 0;
        #10;
        for(S = 0; S < 5'h10; S++) begin
            #10;
            if(Q !== 0) outputFailedTest();
        end

        DIN = 1;
        #10;
        for(S = 0; S < 5'h10; S++) begin
            #10;
            Qzeroed = Q;
            Qzeroed[S[3:0]] = 0;
            if(Q[S[3:0]] !== 1 || |Qzeroed[S[3:0]] !== 0)
                outputFailedTest();
        end
    end

    task outputFailedTest;
        begin
            $fwrite(STDERR, "Failed test:\nDIN - %x\nS - %01x\nQ - %04x\n\n",
                DIN, S[3:0], Q);
        end
    endtask
endmodule
