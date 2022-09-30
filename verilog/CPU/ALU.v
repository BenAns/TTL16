module ALU(input [15:0] A,
	input [15:0] B,
	input [4:0] op,
	output [15:0] Q,
	output overflow,
	output less,
	output equal,
	output greater,
	output zero);

	wire [15:0] Bd;
	wire cin;

	// Get "true" inputs to operations used for some operations
	assign input1 = A & op[0];
	assign input2 = B ^ op[1];

	// Arithmetic operations
	assign {cout, sumout} = input1 + input2 + op[1];

	// Logic operations
	assign andOut = A & B;
	assign orOut = input1 | input2;
	assign xorOut = A ^ B;
	
	// Shift operations
	assign shiftCarry = (op[0] & B[0]) | (op[1] & B[15]);
	assign rightShiftOut = {shiftCarry, B[15:1]};
	assign leftShiftOut = {B[14:0], shiftCarry};
	assign shiftOut = op[0] ? leftShiftOut : rightShiftOut;

	// Get outputs
	assign Q = ~op[4] ? sumout :
		~|op[3:2] ? andOut :
		~op[3] & op[2] ? orOut :
		&op[3:2] & ~|op[2:1] ? xorOut :
		shiftOut;

	assign overflow = (~|op[2:1] & cout) | (~op[1] & op[2] & B[0]);
	assign zero = ~|Q;
	assign isComparison = op[0] & op[1] & ~op[3];
	assign comparisonXOR = op[2] & (A[15] ^ B[15]);
	assign equal = zero & isComparison;
	assign less = (comparisonXOR ^ Q[15]) & isComparison;
	assign greater = ~equal & ~less & isComparison;
endmodule

module ALU_tests;
	reg [15:0] A;
	reg [15:0] B;
	reg [4:0] op;

	wire [15:0] Q;
	wire overflow;
	wire less;
	wire equal;
	wire greater;
	wire zero;
	
	ALU testALU(A, B, op, Q, overflow, less, equal, greater, zero);

	initial begin
		$display("Testing ALU addition");
		$display("Testing ALU subtraction");
		$display("Testing ALU negation");
		$display("Testing ALU signed comparison");
		$display("Testing ALU unsigned comparison");
		$display("Testing ALU AND");
		$display("Testing ALU OR");
		$display("Testing ALU XOR");
		$display("Testing ALU complement");
		$display("Testing ALU arithmetic right shift");
		$display("Testing ALU logical right shift");
		$display("Testing ALU left rotate");
		$display("Testing ALU right rotate");
	end
endmodule
