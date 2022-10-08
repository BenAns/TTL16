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
	wire [15:0] shiftOut = op[1] & op[2] ? leftShiftOut : rightShiftOut;

	// Get outputs
	wire [15:0] Q = ~op[4] ? sumout :
		~|op[3:2] ? andOut :
		~op[3] & op[2] ? orOut :
		&op[3:2] & ~|op[1:0] ? xorOut :
		shiftOut;

	wire overflow = (~op[4] & ~op[3] & cout) | (op[4] & op[3] & ~op[2] & B[0]);
	wire zero = ~|Q;
	wire isComparison = op[0] & op[1] & op[3] & ~op[4];
	wire equal = zero & isComparison;
	wire less = cmpSumExtra & isComparison;
	wire greater = ~equal & ~less & isComparison;
endmodule

module ALU_tests;
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
	initial begin
		$display("Starting main tests");
		
		$display("Testing ALU addition");
		addTestCase(0);
		addTestCase(1);
		addTestCase(2);
		addTestCase(16'h4abc);
		addTestCase(16'haabc);
		addTestCase(16'hffff);
		addTestCase(16'hfffe);

		$display("Testing ALU subtraction");
		subTestCase(0);
		subTestCase(1);
		subTestCase(2);
		subTestCase(16'hffff);
		subTestCase(16'hfffe);
		subTestCase(16'h2abc);
		subTestCase(16'haabc);

		$display("Testing ALU negation");
		negTestCase(0);
		negTestCase(1);
		negTestCase(10);
		negTestCase(10000);
		negTestCase(16'hfffe);
		negTestCase(16'hffff);

		$display("Testing ALU signed comparison");
		cmpTestCase(1, 1);
		cmpTestCase(1, -1);
		cmpTestCase(1, 16'h7fff);
		cmpTestCase(1, 16'h8000);
		cmpTestCase(1, 100);
		cmpTestCase(1, -100);

		$display("Testing ALU unsigned comparison");
		cmpTestCase(0, 0);
		cmpTestCase(0, 1);
		cmpTestCase(0, 16'hffff);
		cmpTestCase(0, 16'h7fff);
		cmpTestCase(0, 16'h8000);
		cmpTestCase(0, 16'h3aaa);
		cmpTestCase(0, 16'haaaa);

		$display("Testing ALU AND");
		andTestCase(0);
		andTestCase(1);
		andTestCase(2);
		andTestCase(16'hffff);
		andTestCase(16'hfffe);
		andTestCase(16'h2abc);
		andTestCase(16'haabc);

		$display("Testing ALU OR");
		orTestCase(0);
		orTestCase(1);
		orTestCase(2);
		orTestCase(16'hffff);
		orTestCase(16'hfffe);
		orTestCase(16'h2abc);
		orTestCase(16'haabc);

		$display("Testing ALU XOR");
		xorTestCase(0);
		xorTestCase(1);
		xorTestCase(2);
		xorTestCase(16'hffff);
		xorTestCase(16'hfffe);
		xorTestCase(16'h2abc);
		xorTestCase(16'haabc);

		$display("Testing ALU complement");
		notTestCase(0);
		notTestCase(1);
		notTestCase(10);
		notTestCase(10000);
		notTestCase(16'hfffe);
		notTestCase(16'hffff);

		$display("Testing ALU arithmetic right shift");
		arsTestCase(0);
		arsTestCase(1);
		arsTestCase(2);
		arsTestCase(5);
		arsTestCase(14);
		arsTestCase(15);
		arsTestCase(16);
		arsTestCase(17);
		arsTestCase(16'hffff);
		arsTestCase(16'hfffe);
		arsTestCase(16'h2abc);
		arsTestCase(16'haabc);

		$display("Testing ALU logical right shift");
		lrsTestCase(0);
		lrsTestCase(1);
		lrsTestCase(2);
		lrsTestCase(5);
		lrsTestCase(14);
		lrsTestCase(15);
		lrsTestCase(16);
		lrsTestCase(17);
		lrsTestCase(16'hffff);
		lrsTestCase(16'hfffe);
		lrsTestCase(16'h2abc);
		lrsTestCase(16'haabc);
	
		$display("Testing ALU left rotate");
		lrotTestCase(0);
		lrotTestCase(1);
		lrotTestCase(2);
		lrotTestCase(5);
		lrotTestCase(14);
		lrotTestCase(15);
		lrotTestCase(16);
		lrotTestCase(17);
		lrotTestCase(16'hffff);
		lrotTestCase(16'hfffe);
		lrotTestCase(16'h2abc);
		lrotTestCase(16'haabc);
		
		$display("Testing ALU right rotate");
		rrotTestCase(0);
		rrotTestCase(1);
		rrotTestCase(2);
		rrotTestCase(5);
		rrotTestCase(14);
		rrotTestCase(15);
		rrotTestCase(16);
		rrotTestCase(17);
		rrotTestCase(16'hffff);
		rrotTestCase(16'hfffe);
		rrotTestCase(16'h2abc);
		rrotTestCase(16'haabc);
	end

	task outputTest(input [255:0] testInfo, input badQ, input badOverflow,
		input badLess, input badEqual, input badGreater, input badZero);
		begin
			$fwrite(STDERR, {"Failed test: %s\n",
				"A - %04x\nB - %04x\nop - %02x\n",
				"Q - %04x\noverflow - %x\nless - %x\n",
				"equal - %x\ngreater - %x\nzero - %x\n",
				"Incorrect values:"},
				testInfo, A, B, op, Q, overflow,
				less, equal, greater, zero);

			if(badQ)        $fwrite(STDERR, " Q");
			if(badOverflow) $fwrite(STDERR, " overflow");
			if(badLess)     $fwrite(STDERR, " less");
			if(badEqual)    $fwrite(STDERR, " equal");
			if(badGreater)  $fwrite(STDERR, " greater");
			if(badZero)     $fwrite(STDERR, " zero");
			$fwrite(STDERR, "\n\n");
		end
	endtask

	task checkTest(input [255:0] testInfo, input [15:0] expQ, input expOverflow,
		input expLess, input expEqual, input expGreater, input expZero);
		reg error;
		reg badQ;
		reg badOverflow;
		reg badLess;
		reg badEqual;
		reg badGreater;
		reg badZero;
		begin
			error = 0;
			badQ = 0;
			badOverflow = 0;
			badLess = 0;
			badEqual = 0;
			badGreater = 0;
			badZero = 0;

			#10;

			if(^expQ !== 1'bx && expQ != Q) begin
				error = 1;
				badQ = 1;
			end
			if(expOverflow != overflow) begin
				error = 1;
				badOverflow = 1;
			end
			if(expLess != less) begin
				error = 1;
				badLess = 1;
			end
			if(expEqual != equal) begin
				error = 1;
				badEqual = 1;
			end
			if(expGreater != greater) begin
				error = 1;
				badGreater = 1;
			end
			if(expZero != zero) begin
				error = 1;
				badZero = 1;
			end

			if(error)
				outputTest(testInfo, badQ, badOverflow,
				badLess, badEqual, badGreater,
				badZero);
		end
	endtask

	task addTestCase(input [15:0] fixedVal);
		reg [1024:0] testName;
		reg [16:0] sum;
		begin
			op = OPCODE_ADD;
			X = fixedVal;
			$sformat(testName, "Adding %04x", fixedVal);

			swappedInputs = 0;
			for(Y = 0; Y < 17'h10000; Y++) begin
				sum = X + Y;

				swappedInputs = 0;
				checkTest(testName, sum[15:0], sum[16],
					1'bx, 1'bx, 1'bx, sum[15:0] == 0);

				swappedInputs = 1;
				checkTest(testName, sum[15:0], sum[16],
					1'bx, 1'bx, 1'bx, sum[15:0] == 0);
			end
		end
	endtask

	task subTestCase(input [15:0] fixedVal);
		reg [1023:0] testName;
		reg [16:0] diff;
		begin
			op = OPCODE_SUB;
			swappedInputs = 0;
			X = fixedVal;
			$sformat(testName, "Subtraction with %04x", fixedVal);

			for(Y = 0; Y < 17'h10000; Y++) begin
				swappedInputs = 0;
				diff = X - Y;
				checkTest(testName, diff[15:0], 1'bx,
					1'bx, 1'bx, 1'bx, diff[15:0] == 0);

				swappedInputs = 1;
				diff = Y - X;
				checkTest(testName, diff[15:0], 1'bx,
					1'bx, 1'bx, 1'bx, diff[15:0] == 0);
			end
		end
	endtask

	task negTestCase(input [15:0] fixedA);
		reg [1023:0] testName;
		begin
			op = OPCODE_NEG;
			swappedInputs = 0;
			X = fixedA;
			$sformat(testName, "Negating with A = %04x", fixedA);

			for(Y = 0; Y < 17'h10000; Y++)
				checkTest(testName, -Y[15:0], 1'bx,
					1'bx, 1'bx, 1'bx, Y == 0);
		end
	endtask

	task cmpTestCase(input signedCmp, input [15:0] fixedVal);
		reg [1023:0] testName;
		reg less;
		reg equal;
		reg greater;
		
		begin
			op = signedCmp ? OPCODE_SCMP : OPCODE_UCMP;	
			X = fixedVal;
			$sformat(testName, "%s comparison with %04x",
				signedCmp ? "Signed" : "Unsigned", fixedVal);

			for(Y = 0; Y < 17'h10000; Y++) begin
				less = signedCmp ? $signed(X[15:0]) < $signed(Y[15:0]) : X < Y;
				equal = X == Y;
				greater = ~less & ~equal;

				swappedInputs = 0;
				checkTest(testName, 1'bx, 1'bx,
					less, equal, greater, 1'bx);

				swappedInputs = 1;
				checkTest(testName, 1'bx, 1'bx,
					greater, equal, less, 1'bx);
			end
		end
	endtask

	task andTestCase(input reg[15:0] fixedVal);
		reg [1023:0] testName;
		begin
			op = OPCODE_AND;
			X = fixedVal;
			$sformat(testName, "ANDing with %04x", fixedVal);

			for(Y = 0; Y < 17'h10000; Y++) begin
				swappedInputs = 0;
				checkTest(testName, X & Y, 1'bx,
					1'bx, 1'bx, 1'bx, (X & Y) == 0);

				swappedInputs = 1;
				checkTest(testName, X & Y, 1'bx,
					1'bx, 1'bx, 1'bx, (X & Y) == 0);
			end
		end
	endtask

	task orTestCase(input reg[15:0] fixedVal);
		reg [1023:0] testName;
		begin
			op = OPCODE_OR;
			X = fixedVal;
			$sformat(testName, "ORing with %04x", fixedVal);

			for(Y = 0; Y < 17'h10000; Y++) begin
				swappedInputs = 0;
				checkTest(testName, X | Y, 1'bx,
					1'bx, 1'bx, 1'bx, (X | Y) == 0);

				swappedInputs = 1;
				checkTest(testName, X | Y, 1'bx,
					1'bx, 1'bx, 1'bx, (X | Y) == 0);
			end
		end
	endtask

	task xorTestCase(input reg[15:0] fixedVal);
		reg [1023:0] testName;
		begin
			op = OPCODE_XOR;
			X = fixedVal;
			$sformat(testName, "XORing with %04x", fixedVal);

			for(Y = 0; Y < 17'h10000; Y++) begin
				swappedInputs = 0;
				checkTest(testName, X ^ Y, 1'bx,
					1'bx, 1'bx, 1'bx, (X ^ Y) == 0);

				swappedInputs = 1;
				checkTest(testName, X ^ Y, 1'bx,
					1'bx, 1'bx, 1'bx, (X ^ Y) == 0);
			end
		end
	endtask

	task notTestCase(input reg[15:0] fixedA);
		reg [1023:0] testName;
		begin
			op = OPCODE_NOT;
			swappedInputs = 0;
			X = fixedA;
			$sformat(testName, "Complement with A = %04x", fixedA);

			for(Y = 0; Y < 17'h10000; Y++)
				checkTest(testName, ~Y[15:0], 1'bx,
					1'bx, 1'bx, 1'bx, Y == 17'h0ffff);
		end
	endtask

	task arsTestCase(input reg[15:0] fixedA);
		reg [1023:0] testName;
		reg [15:0] res;
		begin
			op = OPCODE_ARS;
			swappedInputs = 0;
			X = fixedA;
			$sformat(testName, "Arithmetic right shift with A = %04x", fixedA);

			for(Y = 0; Y < 17'h10000; Y++) begin
				res = (Y[15] << 15) + (Y >> 1);
				checkTest(testName, res, Y[0],
					1'bx, 1'bx, 1'bx, res == 0);
			end
		end
	endtask

	task lrsTestCase(input reg[15:0] fixedA);
		reg [1023:0] testName;
		reg [15:0] res;
		begin
			op = OPCODE_LRS;
			swappedInputs = 0;
			X = fixedA;
			$sformat(testName, "Logical right shift with A = %04x", fixedA);

			for(Y = 0; Y < 17'h10000; Y++) begin
				res = Y >> 1;
				checkTest(testName, res, Y[0],
					1'bx, 1'bx, 1'bx, res == 0);
			end
		end
	endtask

	task lrotTestCase(input reg[15:0] fixedA);
		reg [1023:0] testName;
		reg [15:0] res;
		begin
			op = OPCODE_LROT;
			swappedInputs = 0;
			X = fixedA;
			$sformat(testName, "Left rotate with A = %04x", fixedA);

			for(Y = 0; Y < 17'h10000; Y++) begin
				res = Y[15] + (Y << 1);
				checkTest(testName, res, 0,
					1'bx, 1'bx, 1'bx, res == 0);
			end
		end
	endtask

	task rrotTestCase(input reg[15:0] fixedA);
		reg [1023:0] testName;
		reg [15:0] res;
		begin
			op = OPCODE_RROT;
			swappedInputs = 0;
			X = fixedA;
			$sformat(testName, "Arithmetic right shift with A = %04x", fixedA);

			for(Y = 0; Y < 17'h10000; Y++) begin
				res = (Y[0] << 15) + (Y >> 1);
				checkTest(testName, res, 0,
					1'bx, 1'bx, 1'bx, res == 0);
			end
		end
	endtask
endmodule
