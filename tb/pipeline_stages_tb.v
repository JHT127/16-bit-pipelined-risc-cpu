`timescale 1ns/1ps

module fetch_p (
    input  clk, reset, Call_en, kill,stall,
    input  [2:0] PCSrc,
    input  [15:0] b_target, j_target, forr,
    output reg [15:0] inst, pc, pc_1,
    output [15:0] instruction
);

    wire [15:0] PC, PC_plus_1, next_PC, ret_addr;
    wire [15:0] inst_pre_kill;
    
    adder #(16) pc_plus_1_adder (
        .a(PC),
        .b(16'd1),
        .y(PC_plus_1)
    );

    mux8 #(16) pc_mux (
        .d0(PC_plus_1),
        .d1(b_target),
        .d2(j_target),
        .d3(ret_addr),
        .d4(forr),
        .d5(16'd0),
        .d6(16'd0),
        .d7(16'd0),
        .s(PCSrc),
        .y(next_PC)
    );
    
    flopr #(16) pc_reg (
        .clk(clk),
        .reset(reset),
        .d(stall ? PC : next_PC),
        .q(PC)
    );

    InstructionMem InstructionMemory (
        .PC(PC),
        .instruction(inst_pre_kill)    
    );
    
    flopenr #(16) RR (
        .clk(clk),
        .reset(reset),
        .en(Call_en),
        .d(PC_plus_1),
        .q(ret_addr)
    );

    wire [15:0] bubble = 16'b0;
    
    mux2 #(16) kill_mux (
        .d0(inst_pre_kill),
        .d1(bubble),
        .s(kill),
        .y(instruction)
    );

    flopenr #(16) inst_buff (
        .clk(clk),
        .reset(reset),
        .en(~stall),
        .d(instruction),
        .q(inst)
    );

    flopenr #(16) pc_buff (
        .clk(clk),
        .reset(reset),
        .en(~stall),
        .d(PC),
        .q(pc)
    );

    flopenr #(16) pc_plus1_buff (
        .clk(clk),
        .reset(reset),
        .en(~stall),
        .d(PC_plus_1),
        .q(pc_1)
    );

endmodule

module decode_p (
    input clk, reset, Call_en, for_en, CompSrc, RegWr, Src1, DestReg, ExtOP, stall, kill,
  	input [1:0] Src2, SrcB, FA, FB,
    input [2:0] PCSrc,
    output b_flag,
  	output [15:0] b_sel1, A, B, inst1
);

    wire [15:0] PC, PC_plus_1, next_PC, ret_addr, j_target, instruction;
	wire [15:0] Ext_Imm, b_target, forr, compSecondOperand;
	wire [15:0] BusB, BusW, inst_pre_kill;
	wire [2:0] Rs1, Rs2, Rdest;
  	wire [15:0] Alu_result, BusW_M, BusW;
	wire [15:0] inst, pc, pc_1, inst1, A, B, A1, B1, b_sel1;
	wire [2:0] Rd1;
  
    adder #(16) pc_plus_1_adder (
        .a(PC),
        .b(16'd1),
        .y(PC_plus_1)
    );

    mux8 #(16) pc_mux (
        .d0(PC_plus_1),
        .d1(b_target),
        .d2(j_target),
        .d3(ret_addr),
        .d4(forr),
        .d5(16'd0),
        .d6(16'd0),
        .d7(16'd0),
        .s(PCSrc),
        .y(next_PC)
    );
    
    flopr #(16) pc_reg (
        .clk(clk),
        .reset(reset),
        .d(stall ? PC : next_PC),
        .q(PC)
    );

    InstructionMem InstructionMemory (
        .PC(PC),
        .instruction(inst_pre_kill)    
    );
    
    flopenr #(16) RR (
        .clk(clk),
        .reset(reset),
        .en(Call_en),
        .d(PC_plus_1),
        .q(ret_addr)
    );

    wire [15:0] bubble = 16'b0;
    
    mux2 #(16) kill_mux (
        .d0(inst_pre_kill),
        .d1(bubble),
        .s(kill),
        .y(instruction)
    );

    flopenr #(16) inst_buff (
        .clk(clk),
        .reset(reset),
        .en(~stall),
        .d(instruction),
        .q(inst)
    );

    flopenr #(16) pc_buff (
        .clk(clk),
        .reset(reset),
        .en(~stall),
        .d(PC),
        .q(pc)
    );

    flopenr #(16) pc_plus1_buff (
        .clk(clk),
        .reset(reset),
        .en(~stall),
        .d(PC_plus_1),
        .q(pc_1)
    );
	
    assign j_target = {pc[15:9], inst[11:3]};  
	
	Extender #(6) ext(
        .Ext_Imm(inst[5:0]),
        .ExtOp(ExtOP),
        .extended(Ext_Imm)
    );
	
	adder branch_target(
        .a(pc),
        .b(Ext_Imm),
        .y(b_target)
    );
	
	mux2 #(3) mux_src1(
        .d0(inst[11:9]),
        .d1(inst[8:6]),
        .s(Src1),
        .y(Rs1)
    );


    mux4 #(3) mux_src2(
        .d0(inst[8:6]),
        .d1(inst[5:3]),
        .d2(inst[11:9]),
        .d3(3'd0),
        .s(Src2),
        .y(Rs2)
    );

    mux2 #(3) mux_dest(
        .d0(inst[8:6]),
        .d1(inst[11:9]),
        .s(DestReg),
        .y(Rdest)
    );
  	
    mux4 #(16) ForwardA(
        .d0(BusA),
        .d1(Alu_result),
      	.d2(BusW_M),
        .d3(BusW),
      	.s(FA),
      	.y(A)
    );
  
  	mux4 #(16) ForwardB(
        .d0(BusB),
      	.d1(Alu_result),
      	.d2(BusW_M),
        .d3(BusW),
      	.s(FB),
      	.y(B)
    );
  

    mux4 #(16) b_sel_mux(
      	.d0(B),
        .d1(Ext_Imm),
        .d2(16'd1),
        .d3(16'd0),
        .s(SrcB),
        .y(b_sel)
    );	
	
	mux2 #(16) mux_compSrc(
        .d0(16'd0),
      	.d1(B),
        .s(CompSrc),
        .y(compSecondOperand)
    );
	
	Comparator branch_forLoop_compare(
     .a(A),
	.b(compSecondOperand),
    .equal(b_flag)
    );	
	
	mux2_en #(16) mux_forLoop(
      	.d0(B),
        .d1(pc_1),
        .s(b_flag),
		.en(for_en),
        .y(forr)
    ); 
	
	
	RegFile register_file(
    .clk(clk),
    .RegWr(RegWr),
    .Rs1(Rs1),
	.Rs2(Rs2),
	.Rdest(Rdest),
    .BusW(BusW),
    .BusA(BusA),
	.BusB(BusB)
    );	
	
  	flopr #(16) inst_buff2(
        .clk(clk),
        .reset(reset),
      	.d(inst),
      	.q(inst1)
    );

  	flopr #(16) A_buff (
        .clk(clk),
        .reset(reset),
      	.d(A),
      	.q(A1)
    );

  	flopr #(16) B_buff (
        .clk(clk),
        .reset(reset),
      	.d(B),
      	.q(B1)
    );
  	
  	flopr #(16) Bsel_buff (
        .clk(clk),
        .reset(reset),
        .d(b_sel),
      	.q(b_sel1)
    );
  
  	flopr #(3) destreg_buff (
        .clk(clk),
        .reset(reset),
        .d(Rdest),
    	.q(Rd1)
    );
    
endmodule 

module 	execute_p ( input clk, reset, Call_en, for_en, CompSrc, RegWr, Src1, DestReg, ExtOP, stall, kill,
  				input [1:0] Src2, SrcB, FA, FB,
				input [2:0] PCSrc,Alu_ctrl,
				output zero, 
                 output [15:0] Alu_result_MEM, B2,
                output [2:0] Rd2

    );
  
	
	wire b_flag;
	wire [15:0] b_sel,BusA;	  
	  
  	wire [15:0] PC, PC_plus_1, next_PC, ret_addr, j_target, instruction;
	wire [15:0] Ext_Imm, b_target, forr, compSecondOperand;
	wire [15:0] BusB, BusW, inst_pre_kill;
	wire [2:0] Rs1, Rs2, Rdest;
  	wire [15:0] Alu_result, B_MEM, BusW_M, BusW;
  	wire [15:0] inst, pc, pc_1, inst1, A, B, A1, B1, b_sel1;
  	wire [2:0] Rd1;
	
	
	adder #(16) pc_plus_1_adder (
        .a(PC),
        .b(16'd1),
        .y(PC_plus_1)
    );

    mux8 #(16) pc_mux (
        .d0(PC_plus_1),
        .d1(b_target),
        .d2(j_target),
        .d3(ret_addr),
        .d4(forr),
        .d5(16'd0),
        .d6(16'd0),
        .d7(16'd0),
        .s(PCSrc),
        .y(next_PC)
    );
    
    flopr #(16) pc_reg (
        .clk(clk),
        .reset(reset),
        .d(stall ? PC : next_PC),
        .q(PC)
    );

    InstructionMem InstructionMemory (
        .PC(PC),
        .instruction(inst_pre_kill)    
    );
    
    flopenr #(16) RR (
        .clk(clk),
        .reset(reset),
        .en(Call_en),
        .d(PC_plus_1),
        .q(ret_addr)
    );

    wire [15:0] bubble = 16'b0;
    
    mux2 #(16) kill_mux (
        .d0(inst_pre_kill),
        .d1(bubble),
        .s(kill),
        .y(instruction)
    );

    flopenr #(16) inst_buff (
        .clk(clk),
        .reset(reset),
        .en(~stall),
        .d(instruction),
        .q(inst)
    );

    flopenr #(16) pc_buff (
        .clk(clk),
        .reset(reset),
        .en(~stall),
        .d(PC),
        .q(pc)
    );

    flopenr #(16) pc_plus1_buff (
        .clk(clk),
        .reset(reset),
        .en(~stall),
        .d(PC_plus_1),
        .q(pc_1)
    );
	
    assign j_target = {pc[15:9], inst[11:3]};  
	
	Extender #(6) ext(
        .Ext_Imm(inst[5:0]),
        .ExtOp(ExtOP),
        .extended(Ext_Imm)
    );
	
  adder #(16) branch_target(
        .a(pc),
        .b(Ext_Imm),
        .y(b_target)
    );
	
	mux2 #(3) mux_src1(
        .d0(inst[11:9]),
        .d1(inst[8:6]),
        .s(Src1),
        .y(Rs1)
    );


    mux4 #(3) mux_src2(
        .d0(inst[8:6]),
        .d1(inst[5:3]),
        .d2(inst[11:9]),
        .d3(3'd0),
        .s(Src2),
        .y(Rs2)
    );

    mux2 #(3) mux_dest(
        .d0(inst[8:6]),
        .d1(inst[11:9]),
        .s(DestReg),
        .y(Rdest)
    );
  	
    mux4 #(16) ForwardA(
        .d0(BusA),
        .d1(Alu_result),
      	.d2(BusW_M),
        .d3(BusW),
      	.s(FA),
      	.y(A)
    );
  
  	mux4 #(16) ForwardB(
        .d0(BusB),
      	.d1(Alu_result),
      	.d2(BusW_M),
        .d3(BusW),
      	.s(FB),
      	.y(B)
    );
  

    mux4 #(16) b_sel_mux(
      	.d0(B),
        .d1(Ext_Imm),
        .d2(16'd1),
        .d3(16'd0),
        .s(SrcB),
        .y(b_sel)
    );	
	
	mux2 #(16) mux_compSrc(
        .d0(16'd0),
      	.d1(B),
        .s(CompSrc),
        .y(compSecondOperand)
    );
	
	Comparator branch_forLoop_compare(
     .a(A),
	.b(compSecondOperand),
    .equal(b_flag)
    );	
	
	mux2_en #(16) mux_forLoop(
      	.d0(B),
        .d1(pc_1),
        .s(b_flag),
		.en(for_en),
        .y(forr)
    ); 
	
	
	RegFile register_file(
    .clk(clk),
    .RegWr(RegWr),
    .Rs1(Rs1),
	.Rs2(Rs2),
	.Rdest(Rdest),
    .BusW(BusW),
    .BusA(BusA),
	.BusB(BusB)
    );	
	
  	flopr #(16) inst_buff2(
        .clk(clk),
        .reset(reset),
      	.d(inst),
      	.q(inst1)
    );

  	flopr #(16) A_buff (
        .clk(clk),
        .reset(reset),
      	.d(A),
      	.q(A1)
    );

  	flopr #(16) B_buff (
        .clk(clk),
        .reset(reset),
      	.d(B),
      	.q(B1)
    );
  	
  	flopr #(16) Bsel_buff (
        .clk(clk),
        .reset(reset),
        .d(b_sel),
      	.q(b_sel1)
    );
  
  	flopr #(3) destreg_buff (
        .clk(clk),
        .reset(reset),
        .d(Rdest),
    	.q(Rd1)
    );
    
	
	ALU alu(
     .A(A1), 
     .B(b_sel1),
    .ALU_Ctrl(Alu_ctrl),
    .ALU_res(Alu_result),
    .zero(zero)
    );	
  	
  	flopr #(16) B_buff2(
        .clk(clk),
        .reset(reset),
    	.d(B1),
    	.q(B2)
	    );
	  	
  	flopr #(16) ALU_res_buff(
        .clk(clk),
        .reset(reset),
        .d(Alu_result),
      	.q(Alu_result_MEM)
    );
  
  	flopr #(3) destreg_buff2(
        .clk(clk),
        .reset(reset),
    	.d(Rd1),
    	.q(Rd2)
    );
	
    
endmodule 

module memory_wb_p ( input clk,reset,Call_en,for_en,CompSrc,RegWr,Src1,DestReg,ExtOP,stall, kill, 		MemWr,MemR,WBData,
    input [1:0] Src2,SrcB, FA, FB,
	input [2:0] PCSrc,Alu_ctrl,
	output b_flag,
	output [3:0]opcode,
    output [2:0] func, Rd3,
    output [15:0] BusW_WB
    );	
	
	wire zero;
	wire [15:0] Alu_result;	
	
	wire [15:0] data_memory_out;
	
	wire b_flag;
	wire [15:0] b_sel,BusA;	  
	  
  	wire [15:0] PC, PC_plus_1, next_PC, ret_addr, j_target, instruction;
	wire [15:0] Ext_Imm, b_target, forr, compSecondOperand;
	wire [15:0] BusB, BusW, inst_pre_kill;
	wire [2:0] Rs1, Rs2, Rdest;
  	wire [15:0] Alu_result, Alu_result_MEM, B_MEM, BusW_M, BusW;
  	wire [15:0] inst, pc, pc_1, inst1, A, B, A1, B1, b_sel1;
  	wire [2:0] Rd1, Rd2;
	
	
	adder #(16) pc_plus_1_adder (
        .a(PC),
        .b(16'd1),
        .y(PC_plus_1)
    );

    mux8 #(16) pc_mux (
        .d0(PC_plus_1),
        .d1(b_target),
        .d2(j_target),
        .d3(ret_addr),
        .d4(forr),
        .d5(16'd0),
        .d6(16'd0),
        .d7(16'd0),
        .s(PCSrc),
        .y(next_PC)
    );
    
    flopr #(16) pc_reg (
        .clk(clk),
        .reset(reset),
        .d(stall ? PC : next_PC),
        .q(PC)
    );

    InstructionMem InstructionMemory (
        .PC(PC),
        .instruction(inst_pre_kill)    
    );
    
    flopenr #(16) RR (
        .clk(clk),
        .reset(reset),
        .en(Call_en),
        .d(PC_plus_1),
        .q(ret_addr)
    );

    wire [15:0] bubble = 16'b0;
    
    mux2 #(16) kill_mux (
        .d0(inst_pre_kill),
        .d1(bubble),
        .s(kill),
        .y(instruction)
    );

    flopenr #(16) inst_buff (
        .clk(clk),
        .reset(reset),
        .en(~stall),
        .d(instruction),
        .q(inst)
    );

    flopenr #(16) pc_buff (
        .clk(clk),
        .reset(reset),
        .en(~stall),
        .d(PC),
        .q(pc)
    );

    flopenr #(16) pc_plus1_buff (
        .clk(clk),
        .reset(reset),
        .en(~stall),
        .d(PC_plus_1),
        .q(pc_1)
    );
	
    assign j_target = {pc[15:9], inst[11:3]};  
	
	Extender #(6) ext(
        .Ext_Imm(inst[5:0]),
        .ExtOp(ExtOP),
        .extended(Ext_Imm)
    );
	
  adder #(16) branch_target(
        .a(pc),
        .b(Ext_Imm),
        .y(b_target)
    );
	
	mux2 #(3) mux_src1(
        .d0(inst[11:9]),
        .d1(inst[8:6]),
        .s(Src1),
        .y(Rs1)
    );


    mux4 #(3) mux_src2(
        .d0(inst[8:6]),
        .d1(inst[5:3]),
        .d2(inst[11:9]),
        .d3(3'd0),
        .s(Src2),
        .y(Rs2)
    );

    mux2 #(3) mux_dest(
        .d0(inst[8:6]),
        .d1(inst[11:9]),
        .s(DestReg),
        .y(Rdest)
    );
  	
    mux4 #(16) ForwardA(
        .d0(BusA),
        .d1(Alu_result),
      	.d2(BusW_M),
        .d3(BusW_WB),
      	.s(FA),
      	.y(A)
    );
  
  	mux4 #(16) ForwardB(
        .d0(BusB),
      	.d1(Alu_result),
      	.d2(BusW_M),
        .d3(BusW_WB),
      	.s(FB),
      	.y(B)
    );
  

    mux4 #(16) b_sel_mux(
      	.d0(B),
        .d1(Ext_Imm),
        .d2(16'd1),
        .d3(16'd0),
        .s(SrcB),
        .y(b_sel)
    );	
	
	mux2 #(16) mux_compSrc(
        .d0(16'd0),
      	.d1(B),
        .s(CompSrc),
        .y(compSecondOperand)
    );
	
	Comparator branch_forLoop_compare(
     .a(A),
	.b(compSecondOperand),
    .equal(b_flag)
    );	
	
	mux2_en #(16) mux_forLoop(
      	.d0(B),
        .d1(pc_1),
        .s(b_flag),
		.en(for_en),
        .y(forr)
    ); 
	
	
	RegFile register_file(
    .clk(clk),
    .RegWr(RegWr),
    .Rs1(Rs1),
	.Rs2(Rs2),
	.Rdest(Rdest),
    .BusW(BusW_WB),
    .BusA(BusA),
	.BusB(BusB)
    );	
	
  	flopr #(16) inst_buff2(
        .clk(clk),
        .reset(reset),
      	.d(inst),
      	.q(inst1)
    );

  	flopr #(16) A_buff (
        .clk(clk),
        .reset(reset),
      	.d(A),
      	.q(A1)
    );

  	flopr #(16) B_buff (
        .clk(clk),
        .reset(reset),
      	.d(B),
      	.q(B1)
    );
  	
  	flopr #(16) Bsel_buff (
        .clk(clk),
        .reset(reset),
        .d(b_sel),
      	.q(b_sel1)
    );
  
  	flopr #(3) destreg_buff (
        .clk(clk),
        .reset(reset),
        .d(Rdest),
    	.q(Rd1)
    );
    
	
	ALU alu(
     .A(A1), 
     .B(b_sel1),
    .ALU_Ctrl(Alu_ctrl),
    .ALU_res(Alu_result),
    .zero(zero)
    );	
  	
  	flopr #(16) B_buff2(
        .clk(clk),
        .reset(reset),
    	.d(B1),
    	.q(B2)
	    );
	  	
  	flopr #(16) ALU_res_buff(
        .clk(clk),
        .reset(reset),
        .d(Alu_result),
      	.q(Alu_result_MEM)
    );
  
  	flopr #(3) destreg_buff2(
        .clk(clk),
        .reset(reset),
    	.d(Rd1),
    	.q(Rd2)
    );
		
	
	assign opcode = inst1[15:12];
	assign func = inst1[2:0];
	
	DataMem data_memory(
    .clk(clk),
    .MemR (MemR),
    .MemWr(MemWr),
    .address(Alu_result_MEM),
    .Data_in(B2),
    .Data_out(data_memory_out)
    );	 
	
	mux2 #(16) mux_writeBack(
        .d0(Alu_result_MEM),
        .d1(data_memory_out),
        .s(WBData),
      	.y(BusW_M)
    ); 
  	
  flopr #(16) BusW_WB_buff(
        .clk(clk),
        .reset(reset),
        .d(BusW_M),
    	.q(BusW_WB)
    );
    
  flopr #(3) destreg_buff3 (
        .clk(clk),
        .reset(reset),
    	.d(Rd2),
    	.q(Rd3)
    );
  
endmodule 

//Test Benches:

`timescale 1ns/1ps

module fetch_tb();
    // Inputs
    reg clk;
    reg reset;
    reg Call_en;
    reg kill;
    reg stall;
    reg [2:0] PCSrc;
    reg [15:0] b_target;
    reg [15:0] j_target;
    reg [15:0] forr;
    
    // Outputs
    wire [15:0] instruction;
    wire [15:0] inst;
    wire [15:0] pc;
    wire [15:0] pc_1;
    
    // Instantiate the fetch module
    fetch uut(
        .clk(clk),
        .reset(reset),
        .Call_en(Call_en),
        .kill(kill),
        .stall(stall),
        .PCSrc(PCSrc),
        .b_target(b_target),
        .j_target(j_target),
        .forr(forr),
        .instruction(instruction),
        .inst(inst),
        .pc(pc),
        .pc_1(pc_1)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize inputs
        reset = 1;
        Call_en = 0;
        kill = 0;
        stall = 0;
        PCSrc = 3'b000;
        b_target = 16'h0003;
        j_target = 16'h0005;
        forr = 16'h0002;
        
        // Wait 20ns and release reset
        #20;
        reset = 0;
        PCSrc = 3'b000;
        
        // Test normal execution
        #10;
        
        // Test branch
        PCSrc = 3'b001;
        #10;
        
        // Test jump
        PCSrc = 3'b010;
        #10;
        
        // Test call
        PCSrc = 3'b000;
        Call_en = 1;
        #10;
        
        // Test jump to new target
        PCSrc = 3'b010;
        j_target = 16'h0008;
        #10;
        
        // Test return
        PCSrc = 3'b000;
        Call_en = 0;
        #20;
        
        // Test kill signal
        kill = 1;
        #10;
        kill = 0;
        
        // Test stall signal
        stall = 1;
        #10;
        stall = 0;
        
        // Return to normal execution
        PCSrc = 3'b000;
        #20;
        
        $finish;
    end
    
    // Monitor changes
    initial begin
        $monitor("Time=%0t clk=%b reset=%b PCSrc=%b Call_en=%b kill=%b stall=%b\n\t\
                PC=%h next_PC=%h PC_plus_1=%h\n\t\
                b_target=%h j_target=%h forr=%h\n\t\
                ret_addr=%h instruction=%h\n\t\
                inst=%h pc=%h pc_1=%h\n",
                $time, clk, reset, PCSrc, Call_en, kill, stall,
                uut.PC, uut.next_PC, uut.PC_plus_1,
                b_target, j_target, forr,
                uut.ret_addr, instruction,
                inst, pc, pc_1);
    end
    
    // Display initial memory contents
    initial begin
        $display("\nStarting Fetch Unit Testbench...");
        $display("Instructions in memory (in order):");
        $display("0: 3043  1: 3081  2: 6203  3: 327f");
        $display("4: 0499  5: 1fe0  6: 1002  7: 3040");
        $display("8: 3083  9: 30c4  A: 0251  B: 36ff");
        $display("C: 763e  D: 1002\n");
    end
    
endmodule

/////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module decode_tb();
    reg clk;
    reg reset;
    reg Call_en;
    reg for_en;
    reg CompSrc;
    reg RegWr;
    reg Src1;
    reg DestReg;
    reg ExtOP;
    reg stall;
    reg kill;
    reg [1:0] Src2;
    reg [1:0] SrcB;
    reg [1:0] FA;
    reg [1:0] FB;
    reg [2:0] PCSrc;

    wire b_flag;
    wire [15:0] b_sel1;
    wire [15:0] A;
    wire [15:0] B;
    wire [15:0] inst1;

    decode uut(
        .clk(clk),
        .reset(reset),
        .Call_en(Call_en),
        .for_en(for_en),
        .CompSrc(CompSrc),
        .RegWr(RegWr),
        .Src1(Src1),
        .DestReg(DestReg),
        .ExtOP(ExtOP),
        .stall(stall),
        .kill(kill),
        .Src2(Src2),
        .SrcB(SrcB),
        .FA(FA),
        .FB(FB),
        .PCSrc(PCSrc),
        .b_flag(b_flag),
        .b_sel1(b_sel1),
        .A(A),
        .B(B),
        .inst1(inst1)
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        reset = 1;
        Call_en = 0;
        for_en = 0;
        CompSrc = 0;
        RegWr = 0;
        Src1 = 0;
        DestReg = 0;
        ExtOP = 0;
        stall = 0;
        kill = 0;
        Src2 = 2'b00;
        SrcB = 2'b00;
        FA = 2'b00;
        FB = 2'b00;
        PCSrc = 3'b000;

        #40 reset = 0;

        // Test ADDI
        #20;
        RegWr = 1;
        Src1 = 0;
        DestReg = 0;
        ExtOP = 1;
        SrcB = 2'b01;
        PCSrc = 3'b000;

        // Test BEQ
        #20;
        CompSrc = 1;
        RegWr = 0;
        Src1 = 0;
        Src2 = 2'b00;
        SrcB = 2'b01;
        PCSrc = 3'b001;

        // Test ADD
        #20;
        RegWr = 1;
        Src1 = 1;
        DestReg = 1;
        Src2 = 2'b01;
        SrcB = 2'b00;
        PCSrc = 3'b000;

        // Test JMP
        #20;
        RegWr = 0;
        PCSrc = 3'b010;

        // Test RET
        #20;
        Call_en = 1;
        PCSrc = 3'b011;

        // Test FOR
        #20;
        Call_en = 0;
        for_en = 1;
        PCSrc = 3'b100;

        // Test Stall and Kill
        #20;
        stall = 1;
        kill = 1;

        #40 $finish;
    end

    initial begin
        $monitor("Time=%0t\nControl: reset=%b Call_en=%b for_en=%b CompSrc=%b RegWr=%b\nSrc1=%b DestReg=%b ExtOP=%b stall=%b kill=%b\nSrc2=%b SrcB=%b FA=%b FB=%b PCSrc=%b\nOutputs: b_flag=%b b_sel1=%h A=%h B=%h inst1=%h\n",
            $time, reset, Call_en, for_en, CompSrc, RegWr,
            Src1, DestReg, ExtOP, stall, kill,
            Src2, SrcB, FA, FB, PCSrc,
            b_flag, b_sel1, A, B, inst1);
    end

    initial begin
        $monitor("\nPC=%h inst=%h next_PC=%h b_target=%h j_target=%h ret_addr=%h",
            uut.PC, uut.inst, uut.next_PC, uut.b_target, uut.j_target, uut.ret_addr);
    end

endmodule



/////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module execute_tb();
    reg clk;
    reg reset;
    reg Call_en;
    reg for_en;
    reg CompSrc;
    reg RegWr;
    reg Src1;
    reg DestReg;
    reg ExtOP;
    reg stall;
    reg kill;
    reg [1:0] Src2;
    reg [1:0] SrcB;
    reg [1:0] FA;
    reg [1:0] FB;
    reg [2:0] PCSrc;
    reg [2:0] Alu_ctrl;

    wire zero;
    wire [15:0] Alu_result_MEM, B2;
    wire [2:0] Rd2;

    execute uut(
        .clk(clk),
        .reset(reset),
        .Call_en(Call_en),
        .for_en(for_en),
        .CompSrc(CompSrc),
        .RegWr(RegWr),
        .Src1(Src1),
        .DestReg(DestReg),
        .ExtOP(ExtOP),
        .stall(stall),
        .kill(kill),
        .Src2(Src2),
        .SrcB(SrcB),
        .FA(FA),
        .FB(FB),
        .PCSrc(PCSrc),
        .Alu_ctrl(Alu_ctrl),
        .zero(zero),
        .Alu_result_MEM(Alu_result_MEM),
        .B2(B2),
        .Rd2(Rd2)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        // Initialize all inputs
        reset = 1;
        Call_en = 0;
        for_en = 0;
        CompSrc = 0;
        RegWr = 0;
        Src1 = 0;
        DestReg = 0;
        ExtOP = 0;
        stall = 0;
        kill = 0;
        Src2 = 2'b00;
        SrcB = 2'b00;
        FA = 2'b00;
        FB = 2'b00;
        PCSrc = 3'b000;
        Alu_ctrl = 3'b000;

        // Release reset after 20 time units
        #20 reset = 0;

        // Test case 1: Basic operation
        #10;
        RegWr = 1;
        Src1 = 0;
        DestReg = 0;
        ExtOP = 1;
        SrcB = 2'b01;
        PCSrc = 3'b000;
        Alu_ctrl = 3'b001;

        // Test case 2: Comparator operation
        #10;
        CompSrc = 1;
        RegWr = 0;
        Src1 = 0;
        Src2 = 2'b00;
        SrcB = 2'b01;
        PCSrc = 3'b001;
        Alu_ctrl = 3'b010;

        // Test case 3: Forwarding operation
        #10;
        RegWr = 1;
        Src1 = 1;
        DestReg = 1;
        Src2 = 2'b01;
        SrcB = 2'b00;
        PCSrc = 3'b000;
        Alu_ctrl = 3'b001;
        FA = 2'b01; // Forward from ALU result
        FB = 2'b10; // Forward from memory

        // Test case 4: For-loop operation
        #10;
        Call_en = 0;
        for_en = 1;
        PCSrc = 3'b100;
        Alu_ctrl = 3'b010;

        // End simulation
        #20 $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time=%0t\n", $time);
        $monitor("Control Signals:\n");
        $monitor("reset=%b Call_en=%b for_en=%b CompSrc=%b RegWr=%b\n", 
                reset, Call_en, for_en, CompSrc, RegWr);
        $monitor("Src1=%b DestReg=%b ExtOP=%b Src2=%b SrcB=%b PCSrc=%b Alu_ctrl=%b\n",
                Src1, DestReg, ExtOP, Src2, SrcB, PCSrc, Alu_ctrl);
        $monitor("FA=%b FB=%b stall=%b kill=%b\n", FA, FB, stall, kill);
        $monitor("Results:\n");
        $monitor("ALU_result_MEM=%h B2=%h zero=%b Rd2=%b\n", 
                Alu_result_MEM, B2, zero, Rd2);
        $monitor("Internal Signals:\n");
        $monitor("PC=%h instruction=%h BusA=%h b_sel=%h\n",
                uut.PC, uut.instruction, uut.BusA, uut.b_sel);
        $monitor("--------------------\n");
    end

endmodule


`timescale 1ns/1ps

module memory_wb_p_tb();

    // Inputs
    reg clk;
    reg reset;
    reg Call_en;
    reg for_en;
    reg CompSrc;
    reg RegWr;
    reg Src1;
    reg DestReg;
    reg ExtOP;
    reg stall;
    reg kill;
    reg MemWr;
    reg MemR;
    reg WBData;
    reg [1:0] Src2;
    reg [1:0] SrcB;
    reg [1:0] FA;
    reg [1:0] FB;
    reg [2:0] PCSrc;
    reg [2:0] Alu_ctrl;

    // Outputs
    wire b_flag;
    wire [3:0] opcode;
    wire [2:0] func;
    wire [2:0] Rd3;
    wire [15:0] BusW_WB;

    // Instantiate the Unit Under Test (UUT)
    memory_wb uut(
        .clk(clk),
        .reset(reset),
        .Call_en(Call_en),
        .for_en(for_en),
        .CompSrc(CompSrc),
        .RegWr(RegWr),
        .Src1(Src1),
        .DestReg(DestReg),
        .ExtOP(ExtOP),
        .stall(stall),
        .kill(kill),
        .MemWr(MemWr),
        .MemR(MemR),
        .WBData(WBData),
        .Src2(Src2),
        .SrcB(SrcB),
        .FA(FA),
        .FB(FB),
        .PCSrc(PCSrc),
        .Alu_ctrl(Alu_ctrl),
        .b_flag(b_flag),
        .opcode(opcode),
        .func(func),
        .Rd3(Rd3),
        .BusW_WB(BusW_WB)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Test sequence
    initial begin
        // Initialize all inputs
        reset = 1;
        Call_en = 0;
        for_en = 0;
        CompSrc = 0;
        RegWr = 0;
        Src1 = 0;
        DestReg = 0;
        ExtOP = 0;
        stall = 0;
        kill = 0;
        MemWr = 0;
        MemR = 0;
        WBData = 0;
        Src2 = 2'b00;
        SrcB = 2'b00;
        FA = 2'b00;
        FB = 2'b00;
        PCSrc = 3'b000;
        Alu_ctrl = 3'b000;

        // Release reset after 20 time units
        #40 reset = 0;

        // Test 1: Load Word (lw)
        #20;
        RegWr = 1;
        MemR = 1;
        WBData = 1;
        Src1 = 0;
        DestReg = 0;
        ExtOP = 1;
        SrcB = 2'b01;
        Alu_ctrl = 3'b000;

        // Test 2: Store Word (sw)
        #20;
        RegWr = 0;
        MemR = 0;
        MemWr = 1;
        WBData = 0;
        Src1 = 0;
        ExtOP = 1;
        SrcB = 2'b01;
        Alu_ctrl = 3'b000;

        // Test 3: Add Immediate (addi)
        #20;
        RegWr = 1;
        MemR = 0;
        MemWr = 0;
        WBData = 0;
        Src1 = 0;
        DestReg = 0;
        ExtOP = 1;
        SrcB = 2'b01;
        Alu_ctrl = 3'b000;

        // Test 4: Branch Equal (beq)
        #20;
        RegWr = 0;
        CompSrc = 1;
        Src1 = 0;
        Src2 = 2'b00;
        SrcB = 2'b01;
        PCSrc = 3'b001;
        Alu_ctrl = 3'b001;

        // Test 5: Jump (jmp)
        #20;
        CompSrc = 0;
        PCSrc = 3'b010;

        // Test 6: Call subroutine
        #20;
        Call_en = 1;
        PCSrc = 3'b011;

        // Test 7: For Loop
        #20;
        Call_en = 0;
        for_en = 1;
        PCSrc = 3'b100;
        Alu_ctrl = 3'b000;

        // End simulation
        #40 $finish;
    end

    // Monitor signals
    initial begin
        $monitor("\nTime=%0t", $time);
        $monitor("\nInstruction Operation:");
        $monitor("opcode=%b func=%b", opcode, func);
        
        $monitor("\nControl Signals:");
        $monitor("RegWr=%b MemR=%b MemWr=%b WBData=%b", 
                RegWr, MemR, MemWr, WBData);
        $monitor("CompSrc=%b Src1=%b DestReg=%b ExtOP=%b", 
                CompSrc, Src1, DestReg, ExtOP);
        $monitor("Src2=%b SrcB=%b PCSrc=%b Alu_ctrl=%b",
                Src2, SrcB, PCSrc, Alu_ctrl);
        
        $monitor("\nProcessor State:");
        $monitor("PC=%h instruction=%h", uut.PC, uut.instruction);
        $monitor("ALU_result=%h data_memory_out=%h",
                uut.Alu_result, uut.data_memory_out);
        $monitor("BusA=%h BusB=%h BusW_WB=%h",
                uut.BusA, uut.BusB, uut.BusW_WB);
        $monitor("b_flag=%b branch_target=%h",
                b_flag, uut.b_target);
        
        $monitor("\n----------------------------------------");
    end

    // Monitor memory operations
    initial begin
        $monitor("\nMemory Operation Details:");
        $monitor("Memory Address=%h", uut.Alu_result_MEM);
        $monitor("Memory Write Data=%h", uut.B2);
        $monitor("Memory Read Data=%h", uut.data_memory_out);
        $monitor("Write Back Data=%h", uut.BusW_WB);
    end

endmodule