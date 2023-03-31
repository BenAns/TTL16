module MicrocodeCounter(input inc, input rst, output [3:0] value);
    reg [3:0] value;

    always @(negedge inc) begin
        value = rst ? 0 : value + 1;
    end
endmodule
