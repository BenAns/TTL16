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

	wire cmpSumExtra = (~op[2] & (input1[15] ^ input2[15])) ^ op[2] ^ cout;

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

	wire overflow = (~op[4] & ~op[3] & cout) | (op[4] & op[3] & ~op[2] & B[0]);
	wire zero = ~|Q;
	wire isComparison = op[0] & op[1] & op[3] & ~op[4];
	wire equal = zero & isComparison;
	wire less = cmpSumExtra & isComparison;
	wire greater = ~equal & ~less & isComparison;
endmodule

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
	integer OPCODE_SUB = 5'b00011;
	integer OPCODE_NEG = 5'b00010;
	integer OPCODE_SCMP = 5'b01011;
	integer OPCODE_UCMP = 5'b01111;
	integer OPCODE_AND = 5'b10000;
	integer OPCODE_OR = 5'b10101;
	integer OPCODE_XOR = 5'b11100;
	integer OPCODE_NOT = 5'b10110;
	integer OPCODE_ARS = 5'b11010;
	integer OPCODE_LRS = 5'b11000;
	integer OPCODE_LROT = 5'b11110;
	integer OPCODE_RROT = 5'b11101;

	initial begin
		$display("Starting main tests");
		
		$display("Testing ALU addition");
		swappedInputs = 0;
		#100;
		testAdd();
		swappedInputs = 1;
		#100;
		testAdd();

		$display("Testing ALU subtraction");
		swappedInputs = 0;
		testSub();

		$display("Testing ALU negation");
		testNeg();

		$display("Testing ALU signed comparison");
		testScmp();

		$display("Testing ALU unsigned comparison");
		testUcmp();

		$display("Testing ALU AND");
		$display("Testing ALU OR");
		$display("Testing ALU XOR");

		$display("Testing ALU complement");
		testNot();

		$display("Testing ALU arithmetic right shift");
		$display("Testing ALU logical right shift");
		$display("Testing ALU left rotate");
		$display("Testing ALU right rotate");
	end

	task outputTest(input [255:0] testInfo, input incorrectQ, input incorrectOverflow, input incorrectLess, input incorrectEqual,
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

			if(^expectedQ !== 1'bx && expectedQ !== Q) begin
				error = 1;
				incorrectQ = 1;
			end
			if(expectedOverflow !== 1'bx && expectedOverflow !== overflow) begin
				error = 1;
				incorrectOverflow = 1;
			end
			if(expectedLess !== 1'bx && expectedLess !== less) begin
				error = 1;
				incorrectLess = 1;
			end
			if(expectedEqual !== 1'bx && expectedEqual !== equal) begin
				error = 1;
				incorrectEqual = 1;
			end
			if(expectedEqual !== 1'bx && expectedGreater !== greater) begin
				error = 1;
				incorrectGreater = 1;
			end
			if(expectedZero !== 1'bx && expectedZero !==  zero) begin
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

	task testSub;
		begin
			op = OPCODE_SUB;

			// Test subtracting zero from every integer results
			// in the same integer
			Y = 0;
			for(X = 0; X < 17'h10000; X++)
				checkTest("Subbing zero", X[15:0], 1, 0, 0,
					0, X == 0);
			
			// Test zero subtract any number results in the
			// negative of the number
			X = 0;
			for(Y = 0; Y < 17'h10000; Y++)
				checkTest("Subbing from zero", -Y[15:0],
					Y == 0, 0, 0, 0, Y == 0);
			
			// Test subtracting 0xffff from every integer is
			// equivalent to adding one
			Y = 17'h0ffff;
			for(X = 0; X < 17'h10000; X++)
				checkTest("Subbing 0xffff", X[15:0] + 1,
					X == 17'h0ffff, 0, 0, 0, X == 17'h0ffff);

			// Test subtracting from 0xffff works as should
			// subtracting from -1
			X = 17'h0ffff;
			for(Y = 0; Y < 17'h10000; Y++)
				checkTest("Subbing from 0xffff",
					-1 - Y[15:0], 1, 0, 0, 0,
					Y == 17'h0ffff);
		end
	endtask

	task testNeg;
		begin
			op = OPCODE_NEG;

			// Test every integer Y retrieves its correct -Y,
			// varying X to make sure it is independent of X
			X = 0;
			negTestCase();

			X = 1;
			negTestCase();

			X = 10;
			negTestCase();

			X = 10000;
			negTestCase();

			X = 17'h0fffe;
			negTestCase();

			X = 17'h0ffff;
			negTestCase();
		end
	endtask

	task negTestCase;
		reg [1024:0] testName;
		begin
			for(Y = 0; Y < 17'h10000; Y++) begin
				#1;
				$sformat(testName, "Negating with X = %04x", X[15:0]);
				checkTest(testName, -Y[15:0], 1'bx, 0, 0, 0, Y == 0);
			end;
		end
	endtask

	task testScmp;
		begin
			op = OPCODE_SCMP;

			cmpTestCase(1, 0);
			cmpTestCase(1, 1);
			cmpTestCase(1, -1);
			cmpTestCase(1, 16'h7fff);
			cmpTestCase(1, 16'h8000);
			cmpTestCase(1, 100);
			cmpTestCase(1, -100);
		end
	endtask

	task testUcmp;
		begin
			op = OPCODE_UCMP;

			cmpTestCase(0, 0);
			cmpTestCase(0, 1);
			cmpTestCase(0, 16'hffff);
			cmpTestCase(0, 16'h7fff);
			cmpTestCase(0, 16'h8000);
			cmpTestCase(0, 16'h3aaa);
			cmpTestCase(0, 16'haaaa);
			end
	endtask

	task cmpTestCase(input signedCmp, input [15:0] fixedVal);
		reg [1024:0] testName;
		reg sLess;
		reg sEqual;
		reg sGreater;
		reg uLess;
		reg uEqual;
		reg uGreater;
		reg less;
		reg equal;
		reg greater;
		
		begin
			X = fixedVal;
			
			// With fixed A
			swappedInputs = 0;
			$sformat(testName, "%s comparison for A = %04x",
				signedCmp ? "Signed" : "Unsigned", X[15:0]);

			for(Y = 0; Y < 17'h10000; Y++) begin
				#10;
				sLess = $signed(A) < $signed(B);
				sEqual = $signed(A) == $signed(B);
				sGreater = $signed(A) > $signed(B);

				uLess = $unsigned(A) < $unsigned(B);
				uEqual = $unsigned(A) == $unsigned(B);
				uGreater = $unsigned(A) > $unsigned(B);
				
				#10;
				less = signedCmp ? sLess : uLess;
				equal = signedCmp ? sEqual : uEqual;
				greater = signedCmp ? sGreater : uGreater;

				checkTest(testName, 1'bx, 1'bx,
					less, equal, greater, 1'bx);
			end
			
			// With fixed B
			swappedInputs = 1;
			$sformat(testName, "%s comparison for B = %04x",
				signedCmp ? "Signed" : "unsigned", X[15:0]);

			for(Y = 0; Y < 17'h10000; Y++) begin
				#10;
				sLess = $signed(A) < $signed(B);
				sEqual = $signed(A) == $signed(B);
				sGreater = $signed(A) > $signed(B);

				uLess = $unsigned(A) < $unsigned(B);
				uEqual = $unsigned(A) == $unsigned(B);
				uGreater = $unsigned(A) > $unsigned(B);

				#10;
				less = signedCmp ? sLess : uLess;
				equal = signedCmp ? sEqual : uEqual;
				greater = signedCmp ? sGreater : uGreater;

				checkTest(testName, 1'bx, 1'bx,
					less, equal, greater, 1'bx);
			end

			swappedInputs = 0;
		end
	endtask

	task testAND;
		begin
		end
	endtask

	task testOR;
		begin
		end
	endtask

	task testXOR;
		begin
		end
	endtask

	task testNot;
		begin
			op = OPCODE_NOT;

			// Test every integer Y retrieves its correct ~Y,
			// varying X to make sure it is independent of X
			X = 0;
			notTestCase();

			X = 1;
			notTestCase();

			X = 10;
			notTestCase();

			X = 10000;
			notTestCase();

			X = 17'h0fffe;
			notTestCase();

			X = 17'h0ffff;
			notTestCase();
		end
	endtask

	task notTestCase;
		reg [1024:0] testName;
		begin
			for(Y = 0; Y < 17'h10000; Y++) begin
				#1;
				$sformat(testName, "Complement with X = %04x", X[15:0]);
				checkTest(testName, ~Y[15:0], 0, 0, 0, 0, Y == 17'h0ffff);
			end;
		end
	endtask
endmodule
