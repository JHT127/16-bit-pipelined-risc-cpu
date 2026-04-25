  `include "opcodes.v"
`include "functions.v"	

module controller(
    input  [3:0] opcode,
    input  [2:0] func,
    input        b_flag, stall,  
	input clk,reset,
    output Src1, DestReg, call_en, for_en, CompSrc, kill, ExOp,
    output       [1:0] SrcB, Src2, 
    output       [2:0] ALU_Ctrl, PCSrc,
    output  DERegWr1, DEMemWr, DEMemR, DEWBData,
    output  EMemRegWr2, EMemMemWr, EMemMemR, EMemWBData, MemWbRegWr3,
    // Performance monitor outputs
    output [31:0] total_instructions,
    output [31:0] load_instructions,
    output [31:0] store_instructions,
    output [31:0] alu_instructions,
    output [31:0] control_instructions,
    output [31:0] clock_cycles,
    output [31:0] stall_cycles
);   
    
    wire RegWr, MemR, MemWr, WBData;
    wire [3:0] selectedControlSignals;
    
    pcControl p_c(
        .opcode(opcode), 
        .funct(func),
        .b_flag(b_flag),
        .for_en(for_en_reg),
        .PCSrc(PCSrc),
        .kill(kill),
        .call_en(call_en)
    );
                   
    mainControlUnit m_cu(
        .op(opcode),
        .func(func),
        .Src1(Src1),
        .Src2(Src2),
        .DestReg(DestReg), 
        .RegWr(RegWr),
        .ExOp(ExOp),
        .MemR(MemR),
        .MemWr(MemWr),
        .WBData(WBData), 
        .for_en(for_en),
        .CompSrc(CompSrc),
        .SrcB(SrcB)
    ); 
    
    wire for_en_reg;
    
    flopenr #(1) for_en_register(
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .d(for_en),
        .q(for_en_reg)
    ); 
                    
    aluControl alu_c(
        .opcode(opcode),
        .funct(func),
        .ALU_Ctrl(ALU_Ctrl)
    );  
    
    wire [3:0] controlSignals;
    assign controlSignals = {RegWr, MemWr, MemR, WBData};
    
    mux2 #(4) mux_control_signals_stall(
        .d0(controlSignals),
        .d1(4'b0000),
        .s(stall),
        .y(selectedControlSignals)
    );          
        
    assign {DERegWr1, DEMemWr, DEMemR, DEWBData} = selectedControlSignals;
  
    flopenr #(1) RegWr_reg_ex_mem(
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .d(DERegWr1),
        .q(EMemRegWr2)
    ); 
    
    flopenr #(1) MemR_reg_ex_mem(
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .d(DEMemR),
        .q(EMemMemR)
    ); 
    
    flopenr #(1) MemWr_reg_ex_mem(
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .d(DEMemWr),
        .q(EMemMemWr)
    ); 
    
    flopenr #(1) WBData_reg_ex_mem(
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .d(DEWBData),
        .q(EMemWBData)
    ); 
    
    flopenr #(1) RegWr_reg_mem_wb(
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .d(EMemRegWr2),
        .q(MemWbRegWr3)
    );

    // Performance Monitor Integration
    performance_monitor perf_mon (
        .clk(clk),
        .reset(reset),
        .opcode(opcode),
        .func(func),
        .stall(stall),
        .DERegWr1(DERegWr1),
        .EMemMemR(EMemMemR),
        .EMemMemWr(EMemMemWr),
        .kill(kill),
        .total_instructions(total_instructions),
        .load_instructions(load_instructions),
        .store_instructions(store_instructions),
        .alu_instructions(alu_instructions),
        .control_instructions(control_instructions),
        .clock_cycles(clock_cycles),
        .stall_cycles(stall_cycles)
    );
                     
endmodule
	
//////////////////////////////////

module mainControlUnit(input  [3:0] op,
	           input [2:0] func,
               output       Src1, DestReg, RegWr, ExOp, MemR, MemWr, WBData, for_en, CompSrc,
               output       [1:0] SrcB ,Src2
			   );

  reg [13:0] controlSignals;

  assign {Src1,Src2,DestReg,RegWr,ExOp,MemR,MemWr,WBData,for_en,CompSrc,SrcB} = controlSignals;
 
	  
  always @(*)
	
    case({op,func})
      {`AND, `ANDF} : controlSignals <= 13'b10111x0000x00; 
	  {`ADD, `ADDF} : controlSignals <= 13'b10111x0000x00;
	  {`SUB, `SUBF} : controlSignals <= 13'b10111x0000x00;  
	  {`SLL, `SLLF} : controlSignals <= 13'b10111x0000x00;
	  {`SRL, `SRLF} : controlSignals <= 13'b10111x0000x00;
	  
	  {`ANDI, 3'bxxx}: controlSignals <= 13'b0xx0110000x01; 
	  {`ADDI, 3'bxxx}: controlSignals <= 13'b0xx0100000x01; 
	  
	  {`LW,   3'bxxx}  : controlSignals <= 13'b0xx0101010x01;
	  {`SW,   3'bxxx}  : controlSignals <= 13'b0xxx0001x0x01; 
	  										
	  {`BEQ,  3'bxxx}  : controlSignals <= 13'b000x0000x0101; 
	  {`BNE,  3'bxxx}  : controlSignals <= 13'b000x0000x0101; 
	  {`FOR,  3'bxxx}  : controlSignals <= 13'b11001x0001010; 
	  
	  {`JMP,  `JMPF}   : controlSignals <= 13'bxxxx0x00x0xxx; 
	  {`CALL, `CALLF}  : controlSignals <= 13'bxxxx0x00x0xxx; 
	  {`RET,  `RETF}   : controlSignals <= 13'bxxxx0x00x0xxx; 
	  
	  
	  default: controlSignals <= 13'b1111111111111; // invalid opcode
	  
      
    endcase
endmodule

////////////////////////////////

module aluControl(
    input [3:0] opcode,
    input [2:0] funct,
    output reg [2:0] ALU_Ctrl
);
    always @(*) begin
        case(opcode)
            4'b0000: begin  // R-type instructions
                case(funct)
                    3'b000: ALU_Ctrl = 3'b000;  // AND 
                    3'b001: ALU_Ctrl = 3'b001;  // ADD 
                    3'b010: ALU_Ctrl = 3'b010;  // SUB
                    3'b011: ALU_Ctrl = 3'b011;  // SLL
                    3'b100: ALU_Ctrl = 3'b100;  // SRL
                    default: ALU_Ctrl = 3'bxxx;
                endcase
            end
            
            4'b0010: ALU_Ctrl = 3'b000;  // ANDI
            4'b0011: ALU_Ctrl = 3'b001;  // ADDI
            4'b0100: ALU_Ctrl = 3'b001;  // LW
            4'b0101: ALU_Ctrl = 3'b001;  // SW
            4'b1000: ALU_Ctrl = 3'b010;  // FOR
            default: ALU_Ctrl = 3'bxxx;
        endcase
    end
endmodule

/////////////////////////////////////////

module pcControl(input	[3:0] opcode, 
	             input [2:0] funct,
	             input b_flag,for_en,
	             output [2:0] PCSrc,
	             output kill, call_en);
	
	
	assign PCSrc [0] = ((opcode == `BEQ) && (b_flag == 1) && (for_en == 0)) ||
	((opcode == `BNE) && (b_flag == 0) && (for_en == 0)) || ((opcode == `RET) && (funct == `RETF)&& (for_en == 0)); 
	
	assign PCSrc [1] = ((opcode == `JMP) && (for_en == 0) ) || ((opcode == `CALL) && (for_en == 0) ) || 
	((opcode == `RET) && (for_en == 0) );
	
	assign PCSrc [2] = ((opcode == `FOR) && (for_en == 1)) ;
		
    assign call_en = (opcode == `CALL) && (funct == `CALLF) && (for_en == 0) ;  
	
    assign kill = ((opcode == `BEQ) && (b_flag == 1) && (for_en == 0)) || ((opcode == `BNE) && (b_flag == 0) && (for_en == 0)) ||
    ((opcode == `FOR) && (b_flag == 0) && (for_en == 1)) || ((opcode == `JMP) && (for_en == 0)) || ((opcode == `CALL) && (for_en == 0)) ||
    ((opcode == `RET) && (for_en == 0));
							
endmodule

/////////////////////////////////////////

module performance_monitor (
    input wire clk,
    input wire reset,
    input wire [3:0] opcode,
    input wire [2:0] func,
    input wire stall,
    input wire DERegWr1,      
    input wire EMemMemR,      
    input wire EMemMemWr,     
    input wire kill,          
    
    output reg [31:0] total_instructions,
    output reg [31:0] load_instructions,
    output reg [31:0] store_instructions,
    output reg [31:0] alu_instructions,
    output reg [31:0] control_instructions,
    output reg [31:0] clock_cycles,
    output reg [31:0] stall_cycles
);

    wire is_load, is_store, is_alu, is_control, is_valid_instruction;
    
    assign is_load = (opcode == `LW);
    assign is_store = (opcode == `SW);
    assign is_alu = (opcode == 4'b0000) ||                   // R-type ALU ops
                    (opcode == `ANDI) || (opcode == `ADDI);   // I-type ALU ops
    assign is_control = (opcode == `BEQ) || (opcode == `BNE) ||
                       (opcode == `JMP) || (opcode == `CALL) ||
                       (opcode == `RET) || (opcode == `FOR);
    
    assign is_valid_instruction = !kill && DERegWr1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            total_instructions <= 32'b0;
            load_instructions <= 32'b0;
            store_instructions <= 32'b0;
            alu_instructions <= 32'b0;
            control_instructions <= 32'b0;
            clock_cycles <= 32'b0;
            stall_cycles <= 32'b0;
        end
        else begin
            clock_cycles <= clock_cycles + 1;
            
            if (stall)
                stall_cycles <= stall_cycles + 1;
            
            if (is_valid_instruction) begin
                total_instructions <= total_instructions + 1;
                
                if (is_load)
                    load_instructions <= load_instructions + 1;
                else if (is_store)
                    store_instructions <= store_instructions + 1;
                else if (is_alu)
                    alu_instructions <= alu_instructions + 1;
                else if (is_control)
                    control_instructions <= control_instructions + 1;
            end
        end
    end

endmodule  

`timescale 1ns/1ps

module controller_tb();
    reg [3:0] opcode;
    reg [2:0] func;
    reg b_flag;
    reg stall;
    reg clk_in;
    reg reset;

    wire Src1, DestReg, call_en, for_en, CompSrc, kill, ExOp;
    wire [1:0] SrcB, Src2;
    wire [2:0] ALU_Ctrl, PCSrc;
    wire DERegWr1, DEMemWr, DEMemR, DEWBData;
    wire EMemRegWr2, EMemMemWr, EMemMemR, EMemWBData, MemWbRegWr3;
    wire [31:0] total_instructions;
    wire [31:0] load_instructions;
    wire [31:0] store_instructions;
    wire [31:0] alu_instructions;
    wire [31:0] control_instructions;
    wire [31:0] clock_cycles;
    wire [31:0] stall_cycles;

    controller uut(
        .opcode(opcode),
        .func(func),
        .b_flag(b_flag),
        .stall(stall),
        .clk(clk_in),
        .reset(reset),
        .Src1(Src1),
        .DestReg(DestReg),
        .call_en(call_en),
        .for_en(for_en),
        .CompSrc(CompSrc),
        .kill(kill),
        .ExOp(ExOp),
        .SrcB(SrcB),
        .Src2(Src2),
        .ALU_Ctrl(ALU_Ctrl),
        .PCSrc(PCSrc),
        .DERegWr1(DERegWr1),
        .DEMemWr(DEMemWr),
        .DEMemR(DEMemR),
        .DEWBData(DEWBData),
        .EMemRegWr2(EMemRegWr2),
        .EMemMemWr(EMemMemWr),
        .EMemMemR(EMemMemR),
        .EMemWBData(EMemWBData),
        .MemWbRegWr3(MemWbRegWr3),
        .total_instructions(total_instructions),
        .load_instructions(load_instructions),
        .store_instructions(store_instructions),
        .alu_instructions(alu_instructions),
        .control_instructions(control_instructions),
        .clock_cycles(clock_cycles),
        .stall_cycles(stall_cycles)
    );

    initial begin
        clk_in = 0;
        forever #5 clk_in = ~clk_in;
    end

    initial begin
        reset = 1;
        opcode = 0;
        func = 0;
        b_flag = 0;
        stall = 0;
        #10 reset = 0;

        $display("\nR-type Instructions:");
        $display("Time\tOpcode\tFunc\tControl Signals");
        $display("------------------------------------------------------------");

        #10;
        opcode = 4'b0000; func = 3'b000;
        $display("%0t\tAND\t%b\tSrc1=%b Src2=%b DestReg=%b RegWr=%b ExOp=%b ALU=%b", 
                $time, func, Src1, Src2, DestReg, DERegWr1, ExOp, ALU_Ctrl);

        #10;
        opcode = 4'b0000; func = 3'b001;
        $display("%0t\tADD\t%b\tSrc1=%b Src2=%b DestReg=%b RegWr=%b ExOp=%b ALU=%b", 
                $time, func, Src1, Src2, DestReg, DERegWr1, ExOp, ALU_Ctrl);

        #10;
        opcode = 4'b0000; func = 3'b010;
        $display("%0t\tSUB\t%b\tSrc1=%b Src2=%b DestReg=%b RegWr=%b ExOp=%b ALU=%b", 
                $time, func, Src1, Src2, DestReg, DERegWr1, ExOp, ALU_Ctrl);

        $display("\nI-type Instructions:");
        $display("Time\tOpcode\tControl Signals");
        $display("------------------------------------------------------------");

        #10;
        opcode = 4'b0010; func = 3'b000;
        $display("%0t\tANDI\tSrc1=%b SrcB=%b RegWr=%b ExOp=%b ALU=%b", 
                $time, Src1, SrcB, DERegWr1, ExOp, ALU_Ctrl);

        #10;
        opcode = 4'b0011; func = 3'b000;
        $display("%0t\tADDI\tSrc1=%b SrcB=%b RegWr=%b ExOp=%b ALU=%b", 
                $time, Src1, SrcB, DERegWr1, ExOp, ALU_Ctrl);

        $display("\nMemory Instructions:");
        $display("Time\tOpcode\tMemory Signals");
        $display("------------------------------------------------------------");

        #10;
        opcode = 4'b0100; func = 3'b000;
        $display("%0t\tLW\tMemR=%b WBData=%b RegWr=%b SrcB=%b", 
                $time, DEMemR, DEWBData, DERegWr1, SrcB);

        #10;
        opcode = 4'b0101; func = 3'b000;
        $display("%0t\tSW\tMemWr=%b SrcB=%b", 
                $time, DEMemWr, SrcB);

        $display("\nBranch and Control Instructions:");
        $display("Time\tOpcode\tFunc\tControl Flow Signals");
        $display("------------------------------------------------------------");

        #10;
        opcode = 4'b0110; b_flag = 1; func = 3'b000;
        $display("%0t\tBEQ\t%b\tPCSrc=%b kill=%b b_flag=%b CompSrc=%b", 
                $time, func, PCSrc, kill, b_flag, CompSrc);

        #10;
        opcode = 4'b0111; b_flag = 0; func = 3'b000;
        $display("%0t\tBNE\t%b\tPCSrc=%b kill=%b b_flag=%b CompSrc=%b", 
                $time, func, PCSrc, kill, b_flag, CompSrc);

        #10;
        opcode = 4'b1000; func = 3'b000;
        $display("%0t\tFOR\t%b\tPCSrc=%b kill=%b for_en=%b", 
                $time, func, PCSrc, kill, for_en);

        #10;
        opcode = 4'b0001; func = 3'b000;
        $display("%0t\tJMP\t%b\tPCSrc=%b kill=%b", 
                $time, func, PCSrc, kill);

        #10;
        opcode = 4'b0001; func = 3'b001;
        $display("%0t\tCALL\t%b\tcall_en=%b PCSrc=%b kill=%b", 
                $time, func, call_en, PCSrc, kill);

        #10;
        opcode = 4'b0001; func = 3'b010;
        $display("%0t\tRET\t%b\tPCSrc=%b kill=%b", 
                $time, func, PCSrc, kill);

        $display("\nPipeline Register Values:");
        $display("Time\tDE Stage\t\t\tEMem Stage\t\tMemWb Stage");
        $display("------------------------------------------------------------");
        $display("%0t\tRegWr=%b MemR=%b MemW=%b\tRegWr=%b MemR=%b MemW=%b\tRegWr=%b", 
                $time, DERegWr1, DEMemR, DEMemWr, EMemRegWr2, EMemMemR, EMemMemWr, MemWbRegWr3);

        #10;
        stall = 1;
        $display("\nStall Test:");
        $display("Time\tStall Signals");
        $display("------------------------------------------------------------");
        $display("%0t\tDERegWr1=%b DEMemWr=%b DEMemR=%b DEWBData=%b", 
                $time, DERegWr1, DEMemWr, DEMemR, DEWBData);

        #10;
        $display("\nPerformance Monitor Values:");
        $display("------------------------------------------------------------");
        $display("Total Instructions: %d", total_instructions);
        $display("Load Instructions: %d", load_instructions);
        $display("Store Instructions: %d", store_instructions);
        $display("ALU Instructions: %d", alu_instructions);
        $display("Control Instructions: %d", control_instructions);
        $display("Clock Cycles: %d", clock_cycles);
        $display("Stall Cycles: %d", stall_cycles);

        #10 $finish;
end

endmodule
