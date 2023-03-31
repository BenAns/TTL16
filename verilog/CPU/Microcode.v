// Combinational logic for CPU microcode
module Microcode(input [3:0] Counter,
    input [15:0] Instr,
    input [4:0] Flags,
    output reg CounterRST,
    output reg PCToA,
    output reg PCW,
    output reg PCWriteFromD,
    output reg DToInstr,
    output reg ALUToD,
    output reg [3:0] rsel0RegFile,
    output reg [3:0] rsel1RegFile,
    output reg [3:0] wselRegFile,
    output reg wRegFile,
    output reg shiftInstrToD,
    output reg wFlags,
    output reg rsel0ToA,
    output reg rsel1ToD,
    output reg wOut,
    output reg enableInterrupts);
    
    always @(Counter, Instr) begin
        // Default output values to be overwritten
        CounterRST = 0;
        PCToA = 0;
        PCW = 0;
        PCWriteFromD = 0;
        DToInstr = 0;
        ALUToD = 0;
        rsel0RegFile[3:0] = 4'b0000;
        rsel1RegFile[3:0] = 4'b0000;
        wselRegFile[3:0] = 4'b0000;
        wRegFile = 0;
        shiftInstrToD = 0;
        wFlags = 0;
        rsel0ToA = 0;
        rsel1ToD = 0;
        wOut = 0;
        enableInterrupts = 0;

        case(Counter)
            4'h0: // Output PC to address line
                     PCToA = 1;

            4'h1: begin // Read data bus 0 to Instr
                     PCToA = 1;
                     DToInstr = 1;
                     PCW = 1;
                  end

            default: // Handle individual instructions
                     if (!Instr[15] || ~Instr[14:10])
                        memInstr();
                     else if (Instr[14] == 1)
                        arithCmpInstr();
                     else
                        branchInstr();
        endcase
    end

    task memInstr;
        begin
            if (!Instr[15]) begin  // LDVAL
                case(Counter)
                    4'h2: begin // Setup values to write
                             shiftInstrToD = 1;
                             wselRegFile[3:0] = Instr[3:0];
                          end

                    4'h3: begin // Perform write
                             shiftInstrToD = 1;
                             wselRegFile[3:0] = Instr[3:0];
                             wRegFile = 1;
                          end

                    default: begin
                                CounterRST = 1;
                                PCW = 1;
                             end
                endcase
            end else if(!Instr[8]) begin  // LDMEM
                case(Counter)
                    4'h2: begin // Setup values
                             rsel0RegFile[3:0] = Instr[3:0];
                             rsel0ToA = 1;
                             wselRegFile[3:0] = Instr[7:4];
                          end

                    4'h3: begin // Perform write
                             rsel0RegFile[3:0] = Instr[3:0];
                             rsel0ToA = 1;
                             wselRegFile[3:0] = Instr[7:4];
                             wRegFile = 1;
                          end

                     default: begin
                                CounterRST = 1;
                                PCW = 1;
                              end
                endcase
            end else if(!Instr[9]) begin  // STR
                case(Counter)
                    4'h2: begin // Setup values
                             rsel0RegFile[3:0] = Instr[3:0];
                             rsel0ToA = 1;
                             rsel1RegFile[3:0] = Instr[7:4];
                             rsel1ToD = 1;
                          end

                    4'h3: begin // Perform write
                             rsel0RegFile[3:0] = Instr[3:0];
                             rsel0ToA = 1;
                             rsel1RegFile[3:0] = Instr[7:4];
                             rsel1ToD = 1;
                             wOut = 1;
                           end

                    default: begin
                                CounterRST = 1;
                                PCW = 1;
                             end
                endcase
            end else begin  // MOV
                case(Counter)
                    4'h2: begin // Setup values
                             wselRegFile[3:0] = Instr[7:4];
                             rsel1RegFile[3:0] = Instr[3:0];
                             rsel1ToD = 1;
                          end

                    4'h3: begin // Perform write
                             wselRegFile[3:0] = Instr[7:4];
                             rsel1RegFile[3:0] = Instr[3:0];
                             rsel1ToD = 1;
                             wRegFile = 1;
                          end

                    default: begin
                                CounterRST = 1;
                                PCW = 1;
                             end
                endcase
            end
        end
    endtask

    task arithCmpInstr;
        begin
            case(Counter)
                4'h2: begin // Perform ALU calculation
                         rsel0RegFile[3:0] = Instr[7:4];
                         rsel1RegFile[3:0] = Instr[3:0];
                         ALUToD = ~Instr[13];
                      end
                         
                4'h3: begin // Save value to R0, write flags
                         rsel0RegFile[3:0] = Instr[7:4];
                         rsel1RegFile[3:0] = Instr[3:0];
                         ALUToD = ~Instr[13];
                         wRegFile = 1;
                         wFlags = 1;
                      end

                default: begin
                            CounterRST = 1;
                            PCW = 1;
                         end
            endcase
        end
    endtask

    task branchInstr;
        begin
            case(Counter)
                4'h2: begin // Setup branch
                         rsel1RegFile[3:0] = Instr[3:0];
                         rsel1ToD = 1;
                         enableInterrupts = Instr[11];
                         PCWriteFromD = |(Instr[9:4] & {1'b1, (Flags ^ {Instr[10], Instr[10], Instr[10], Instr[10], Instr[10]})});
                      end

                default: begin
                            CounterRST = 1;
                            PCW = 1;
                         end
            endcase
        end
    endtask
endmodule
