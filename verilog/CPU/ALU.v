module ALU(input [15:0] A,
	input [15:0] B,
	input [4:0] op,
	output [15:0] Q,
	output overflow,
	output less,
	output equal,
	output greater,
	output zero);

	// Get "true" inputs to operations used for some operations
	wire [15:0] input1 = A & {16{op[0]}};
	wire [15:0] input2 = B ^ {16{op[1]}};

	// Arithmetic operations
	wire cout;
	wire [15:0] sumout;
	assign {cout, sumout[15:0]} = input1 + input2 + op[1];

	// Logic operations
	wire [15:0] andOut = A & B;
	wire [15:0] orOut = input1 | input2;
	wire [15:0] xorOut = A ^ B;
	
	// Shift operations
	wire shiftCarry = (op[0] & B[0]) | (op[1] & B[15]);
	wire [15:0] rightShiftOut = {shiftCarry, B[15:1]};
	wire [15:0] leftShiftOut = {B[14:0], shiftCarry};
	wire [15:0] shiftOut = op[0] ? leftShiftOut : rightShiftOut;

	// Get outputs
	wire [15:0] Q = ~op[4] ? sumout :
		~|op[3:2] ? andOut :
		~op[3] & op[2] ? orOut :
		&op[3:2] & ~|op[2:1] ? xorOut :
		shiftOut;

	wire overflow = (~|op[2:1] & cout) | (~op[1] & op[2] & B[0]);
	wire zero = ~|Q;
	wire isComparison = op[0] & op[1] & ~op[3];
	wire comparisonXOR = op[2] & (A[15] ^ B[15]);
	wire equal = zero & isComparison;
	wire less = (comparisonXOR ^ Q[15]) & isComparison;
	wire greater = ~equal & ~less & isComparison;
endmodule

`define OPCODE_SUB
`define OPCODE_NEG
`define OPCODE_SCMP
`define OPCODE_USMP
`define OPCODE_AND
`define OPCODE_OR
`define OPCODE_XOR
`define OPCODE_NOT
`define OPCODE_ARS
`define OPCODE_LRS
`define OPCODE_LROT
`define OPCODE_RROT

`timescale 1us/10ns

module ALU_tests;
	reg [16:0] X;
	reg [16:0] Y;
	reg [4:0] op;

	wire [15:0] Q;
	wire overflow;
	wire less;
	wire equal;
	wire greater;
	wire zero;

	reg swappedInputs;
	wire [15:0] A = swappedInputs ? Y[15:0] : X[15:0];
	wire [15:0] B = swappedInputs ? X[15:0] : Y[15:0];
	
	ALU testALU(A, B, op, Q, overflow, less, equal, greater, zero);

	integer STDERR = 32'h80000002;
	integer OPCODE_ADD = 5'b00001;

	initial begin
		$display("Starting main tests");

		swappedInputs = 0;
		#100;
		performMainTests();

		swappedInputs = 1;
		#100;
		performMainTests();
	end

	task performMainTests;
		begin
			$display("Testing ALU addition");
			testAdd();


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
	endtask

	task outputTest(input [255:0] testInfo, input incorrectQ,
		input incorrectOverflow, input incorrectLess, input incorrectEqual,
		input incorrectGreater, input incorrectZero);
		begin
			$fwrite(STDERR, {"Failed test: %s\n",
				"A - %04x\nB - %04x\nop - %02x\n",
				"Q - %04x\noverflow - %x\nless - %x\n",
				"equal - %x\ngreater - %x\nzero - %x\n",
				"Incorrect values:"},
				testInfo, A, B, op, Q, overflow,
				less, equal, greater, zero);

			if(incorrectQ)        $fwrite(STDERR, " Q");
			if(incorrectOverflow) $fwrite(STDERR, " overflow");
			if(incorrectLess)     $fwrite(STDERR, " less");
			if(incorrectEqual)    $fwrite(STDERR, " equal");
			if(incorrectGreater)  $fwrite(STDERR, " greater");
			if(incorrectZero)     $fwrite(STDERR, " zero");
			$fwrite(STDERR, "\n\n");

			incorrectQ = 0;
			incorrectOverflow = 0;
			incorrectLess = 0;
			incorrectEqual = 0;
			incorrectGreater = 0;
			incorrectZero = 0;
		end
	endtask

	task checkTest(input [255:0] testInfo, input [15:0] expectedQ,
		input expectedOverflow, input expectedLess, input expectedEqual,
		input expectedGreater, input expectedZero);
		reg error;
		reg incorrectQ;
		reg incorrectOverflow;
		reg incorrectLess;
		reg incorrectEqual;
		reg incorrectGreater;
		reg incorrectZero;
		begin
			error = 0;
			incorrectQ = 0;
			incorrectOverflow = 0;
			incorrectLess = 0;
			incorrectEqual = 0;
			incorrectGreater = 0;
			incorrectZero = 0;

			#100;

			if(expectedQ !== Q) begin
				error = 1;
				incorrectQ = 1;
			end
			if(expectedOverflow !== overflow) begin
				error = 1;
				incorrectOverflow = 1;
			end
			if(expectedLess !== less) begin
				error = 1;
				incorrectLess = 1;
			end
			if(expectedEqual !== equal) begin
				error = 1;
				incorrectEqual = 1;
			end
			if(expectedGreater !== greater) begin
				error = 1;
				incorrectGreater = 1;
			end
			if(expectedZero !==  zero) begin
				error = 1;
				incorrectZero = 1;
			end

			if(error)
				outputTest(testInfo, incorrectQ, incorrectOverflow,
				incorrectLess, incorrectEqual, incorrectGreater,
				incorrectZero);
		end
	endtask

	task testAdd;
		begin
			op = OPCODE_ADD;

			// Test adding zero to every integer results in the same
			// integer with no carry or comparison flags
			X = 0;
			for(Y = 0; Y < 17'h10000; Y++)
				checkTest("Adding zero", Y[15:0], 0, 0, 0, 0,
					Y == 0);

			// Test adding 0xffff to every integer is equivalent
			// to subtracting one and setting carry if necessary
			X = 17'h0ffff;
			for(Y = 0; Y < 17'h10000; Y++)
				checkTest("Adding 0xffff", Y[15:0] - 1,
					Y != 0, 0, 0, 0, Y == 1);

			// Test adding one to every integer works correctly
			X = 1; 
			for(Y = 0; Y < 17'h10000; Y++)
				checkTest("Adding one", Y[15:0] + 1,
					Y == 17'h0ffff, 0, 0, 0,
					Y == 17'h0ffff);
		end
	endtask
endmodule
