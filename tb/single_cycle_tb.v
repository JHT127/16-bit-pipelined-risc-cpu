`timescale 1ns/1ps

module fetch (input clk,reset,Call_en,
	input [2:0] PCSrc,
	input [15:0] b_target, j_target,forr,
	output [15:0] instrution);
	
	wire [15:0] PC, PC_plus_1, next_PC,ret_addr;
	
	
	adder pc_plus_1(
        .a(PC),
        .b(16'd1),
        .y(PC_plus_1)
    );

	mux8 #(16) pc_mux(
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
	
	flopr pc_reg(
        .clk(clk),
        .reset(reset),
        .d(next_PC),
        .q(PC)
    );
	
	InstructionMem InstructionMemory(
        .PC(PC),
        .instruction(instrution)
    ); 
	
	flopenr #(16) RR(
        .clk(clk),
        .reset(reset),
        .en(Call_en),
        .d(PC_plus_1),
        .q(ret_addr)
    );
    
endmodule 	 


`timescale 1ns/1ps

module fetch_tb();
    reg clk;
    reg reset;
    reg Call_en;
    reg [2:0] PCSrc;
    reg [15:0] b_target;
    reg [15:0] j_target;
    reg [15:0] forr;
    wire [15:0] instrution;

    fetch uut(
        .clk(clk),
        .reset(reset),
        .Call_en(Call_en),
        .PCSrc(PCSrc),
        .b_target(b_target),
        .j_target(j_target),
        .forr(forr),
        .instrution(instrution)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1;
        Call_en = 0;
        PCSrc = 3'b000;
        b_target = 16'h0003;    
        j_target = 16'h0005;    
        forr = 16'h0002;        
        #20;
        reset = 0;
        PCSrc = 3'b000;
        #10;
        
        PCSrc = 3'b001;
        #10;
        
        PCSrc = 3'b010;
        #10;
        
        PCSrc = 3'b000;
        Call_en = 1;
        #10;
        
        PCSrc = 3'b010;
        j_target = 16'h0008;    
        #10;
        
        PCSrc = 3'b000;
        Call_en = 0;
        #20;
        
        PCSrc = 3'b011;
        #10;
        
        PCSrc = 3'b100;
        #10;
        
        PCSrc = 3'b000;
        #20;
        
        $finish;
    end
    
    initial begin
        $monitor("Time=%0t clk=%b reset=%b PCSrc=%b Call_en=%b\n\tPC=%h next_PC=%h PC_plus_1=%h\n\tb_target=%h j_target=%h forr=%h\n\tret_addr=%h instruction=%h\n",
                 $time, clk, reset, PCSrc, Call_en,
                 uut.PC, uut.next_PC, uut.PC_plus_1,
                 b_target, j_target, forr,
                 uut.ret_addr, instrution);
    end

    initial begin
        $display("\nStarting Fetch Unit Testbench...");
        $display("Instructions in memory (in order):");
        $display("0: 3043  1: 3081  2: 6203  3: 327f");
        $display("4: 0499  5: 1fe0  6: 1002  7: 3040");
        $display("8: 3083  9: 30c4  A: 0251  B: 36ff");
        $display("C: 763e  D: 1002\n");
    end

endmodule		   

///////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module decode ( input clk,reset,Call_en,for_en,CompSrc,RegWr,Src1,DestReg,ExtOP,
	input [1:0] Src2,SrcB,
	input [2:0] PCSrc,
	output b_flag,
	output [15:0] b_sel,BusA);
	
	wire [15:0] PC, PC_plus_1, next_PC,ret_addr,j_target, instruction; 
	wire [15:0] Ext_Imm; 
    wire [15:0] b_target,forr,compSecondOperand;
	wire [15:0] BusB,BusW;
	wire [2:0] Rs1,Rs2,Rdest;
	
	
	adder pc_plus_1(
        .a(PC),
        .b(16'd1),
        .y(PC_plus_1)
    );

	mux8 #(16) pc_mux(
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
	
	flopr pc_reg(
        .clk(clk),
        .reset(reset),
        .d(next_PC),
        .q(PC)
    );
	
	InstructionMem InstructionMemory(
        .PC(PC),
        .instruction(instruction)
    ); 
	
	flopenr #(16) RR(
        .clk(clk),
        .reset(reset),
        .en(Call_en),
        .d(PC_plus_1),
        .q(ret_addr)
    );	  
	
	assign j_target = {PC[15:9], instruction[11:3]};  
	
	Extender #(6) ext(
        .Ext_Imm(instruction[5:0]),
        .ExtOp(ExtOP),
        .extended(Ext_Imm)
    );
	
	adder branch_target(
        .a(PC),
        .b(Ext_Imm),
        .y(b_target)
    );
	
	mux2 #(3) mux_src1(
        .d0(instruction[11:9]),
        .d1(instruction[8:6]),
        .s(Src1),
        .y(Rs1)
    );


    mux4 #(3) mux_src2(
        .d0(instruction[8:6]),
        .d1(instruction[5:3]),
        .d2(instruction[11:9]),
        .d3(3'd0),
        .s(Src2),
        .y(Rs2)
    );

    mux2 #(3) mux_dest(
        .d0(instruction[8:6]),
        .d1(instruction[11:9]),
        .s(DestReg),
        .y(Rdest)
    );

    mux4 #(16) b_sel_mux(
        .d0(BusB),
        .d1(Ext_Imm),
        .d2(16'd1),
        .d3(16'd0),
        .s(SrcB),
        .y(b_sel)
    );	
	
	mux2 #(16) mux_compSrc(
        .d0(16'd0),
        .d1(BusB),
        .s(CompSrc),
        .y(compSecondOperand)
    );
	
	Comparator branch_forLoop_compare(
    .a(BusA),
	.b(compSecondOperand),
    .equal(b_flag)
    );	
	
	mux2_en #(16) mux_forLoop(
        .d0(BusB),
        .d1(PC_plus_1),
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
	
    
endmodule 

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
    reg [1:0] Src2;
    reg [1:0] SrcB;
    reg [2:0] PCSrc;

    wire b_flag;
    wire [15:0] b_sel;
    wire [15:0] BusA;

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
        .Src2(Src2),
        .SrcB(SrcB),
        .PCSrc(PCSrc),
        .b_flag(b_flag),
        .b_sel(b_sel),
        .BusA(BusA)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
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
        Src2 = 2'b00;
        SrcB = 2'b00;
        PCSrc = 3'b000;

        #20 reset = 0;

        // Test ADDI
        #10;
        RegWr = 1;
        Src1 = 0;
        DestReg = 0;
        ExtOP = 1;
        SrcB = 2'b01;
        PCSrc = 3'b000;

        // Test BEQ
        #10;
        CompSrc = 1;
        RegWr = 0;
        Src1 = 0;
        Src2 = 2'b00;
        SrcB = 2'b01;
        PCSrc = 3'b001;

        // Test ADD
        #10;
        RegWr = 1;
        Src1 = 1;
        DestReg = 1;
        Src2 = 2'b01;
        SrcB = 2'b00;
        PCSrc = 3'b000;

        // Test JMP
        #10;
        RegWr = 0;
        PCSrc = 3'b010;

        // Test RET
        #10;
        Call_en = 1;
        PCSrc = 3'b011;

        // Test FOR
        #10;
        Call_en = 0;
        for_en = 1;
        PCSrc = 3'b100;

        #20 $finish;
    end

    initial begin
        $monitor("Time=%0t\nControl: reset=%b Call_en=%b for_en=%b CompSrc=%b RegWr=%b\nSrc1=%b DestReg=%b ExtOP=%b Src2=%b SrcB=%b PCSrc=%b\nOutputs: b_flag=%b b_sel=%h BusA=%h\n",
            $time, reset, Call_en, for_en, CompSrc, RegWr,
            Src1, DestReg, ExtOP, Src2, SrcB, PCSrc,
            b_flag, b_sel, BusA);
    end

    initial begin
        $monitor("\nPC=%h instr=%h PC_next=%h b_target=%h j_target=%h ret_addr=%h",
            uut.PC, uut.instruction, uut.next_PC, uut.b_target, uut.j_target, uut.ret_addr);
    end

endmodule	 

///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module 	execute ( input clk,reset,Call_en,for_en,CompSrc,RegWr,Src1,DestReg,ExtOP,
	input [1:0] Src2,SrcB,
	input [2:0] PCSrc,Alu_ctrl,
	output zero,
	output [15:0] Alu_result);	 
	
	wire b_flag;
	wire [15:0] b_sel,BusA;	  
	
	wire [15:0] PC, PC_plus_1, next_PC,ret_addr,j_target, instruction; 
	wire [15:0] Ext_Imm; 
    wire [15:0] b_target,forr,compSecondOperand;
	wire [15:0] BusB,BusW;
	wire [2:0] Rs1,Rs2,Rdest;
	
	
	adder pc_plus_1(
        .a(PC),
        .b(16'd1),
        .y(PC_plus_1)
    );

	mux8 #(16) pc_mux(
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
	
	flopr pc_reg(
        .clk(clk),
        .reset(reset),
        .d(next_PC),
        .q(PC)
    );
	
	InstructionMem InstructionMemory(
        .PC(PC),
        .instruction(instruction)
    ); 
	
	flopenr #(16) RR(
        .clk(clk),
        .reset(reset),
        .en(Call_en),
        .d(PC_plus_1),
        .q(ret_addr)
    );	  
	
	assign j_target = {PC[15:9], instruction[11:3]};  
	
	Extender #(6) ext(
        .Ext_Imm(instruction[5:0]),
        .ExtOp(ExtOP),
        .extended(Ext_Imm)
    );
	
	adder branch_target(
        .a(PC),
        .b(Ext_Imm),
        .y(b_target)
    );
	
	mux2 #(3) mux_src1(
        .d0(instruction[11:9]),
        .d1(instruction[8:6]),
        .s(Src1),
        .y(Rs1)
    );


    mux4 #(3) mux_src2(
        .d0(instruction[8:6]),
        .d1(instruction[5:3]),
        .d2(instruction[11:9]),
        .d3(3'd0),
        .s(Src2),
        .y(Rs2)
    );

    mux2 #(3) mux_dest(
        .d0(instruction[8:6]),
        .d1(instruction[11:9]),
        .s(DestReg),
        .y(Rdest)
    );

    mux4 #(16) b_sel_mux(
        .d0(BusB),
        .d1(Ext_Imm),
        .d2(16'd1),
        .d3(16'd0),
        .s(SrcB),
        .y(b_sel)
    );	
	
	mux2 #(16) mux_compSrc(
        .d0(16'd0),
        .d1(BusB),
        .s(CompSrc),
        .y(compSecondOperand)
    );
	
	Comparator branch_forLoop_compare(
    .a(BusA),
	.b(compSecondOperand),
    .equal(b_flag)
    );	
	
	mux2_en #(16) mux_forLoop(
        .d0(BusB),
        .d1(PC_plus_1),
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
	
	
	ALU alu(
    .A(BusA), 
	.B(b_sel),
    .ALU_Ctrl(Alu_ctrl),
    .ALU_res(Alu_result),
    .zero(zero)
    );	
	
    
endmodule 
	
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
    reg [1:0] Src2;
    reg [1:0] SrcB;
    reg [2:0] PCSrc;
    reg [2:0] Alu_ctrl;

    wire zero;
    wire [15:0] Alu_result;

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
        .Src2(Src2),
        .SrcB(SrcB),
        .PCSrc(PCSrc),
        .Alu_ctrl(Alu_ctrl),
        .zero(zero),
        .Alu_result(Alu_result)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
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
        Src2 = 2'b00;
        SrcB = 2'b00;
        PCSrc = 3'b000;
        Alu_ctrl = 3'b000;

        #20 reset = 0;

        
        #10;
        RegWr = 1;
        Src1 = 0;
        DestReg = 0;
        ExtOP = 1;
        SrcB = 2'b01;
        PCSrc = 3'b000;
        Alu_ctrl = 3'b001;  

        
        #10;
        CompSrc = 1;
        RegWr = 0;
        Src1 = 0;
        Src2 = 2'b00;
        SrcB = 2'b01;
        PCSrc = 3'b001;
        Alu_ctrl = 3'b010;  

        
        #10;
        RegWr = 1;
        Src1 = 1;
        DestReg = 1;
        Src2 = 2'b01;
        SrcB = 2'b00;
        PCSrc = 3'b000;
        Alu_ctrl = 3'b001;  

        
        
        #10;
        Call_en = 0;
        for_en = 1;
        PCSrc = 3'b100;
        Alu_ctrl = 3'b010;  

        #20 $finish;
    end

    initial begin
        $monitor("Time=%0t\n", $time);
        $monitor("Control Signals:\n");
        $monitor("reset=%b Call_en=%b for_en=%b CompSrc=%b RegWr=%b\n", 
                reset, Call_en, for_en, CompSrc, RegWr);
        $monitor("Src1=%b DestReg=%b ExtOP=%b Src2=%b SrcB=%b PCSrc=%b Alu_ctrl=%b\n",
                Src1, DestReg, ExtOP, Src2, SrcB, PCSrc, Alu_ctrl);
        $monitor("Results:\n");
        $monitor("ALU_result=%h zero=%b\n", Alu_result, zero);
        $monitor("Internal Signals:\n");
        $monitor("PC=%h instruction=%h BusA=%h b_sel=%h\n",
                uut.PC, uut.instruction, uut.BusA, uut.b_sel);
        $monitor("--------------------\n");
    end

endmodule	

//////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module memory_wb ( input clk,reset,Call_en,for_en,CompSrc,RegWr,Src1,DestReg,ExtOP,
	MemWr,MemR,WBData,
	input [1:0] Src2,SrcB,
	input [2:0] PCSrc,Alu_ctrl,
	output b_flag,
	output [3:0]opcode,
	output [2:0] func);	
	
	wire zero;
	wire [15:0] Alu_result;	
	
	wire [15:0] b_sel,BusA;	  
	wire [15:0] PC, PC_plus_1, next_PC,ret_addr,j_target, instruction; 
	wire [15:0] Ext_Imm; 
    wire [15:0] b_target,forr,compSecondOperand;
	wire [15:0] BusB,BusW;
	wire [2:0] Rs1,Rs2,Rdest;
	wire [15:0] data_memory_out;
	
	adder pc_plus_1(
        .a(PC),
        .b(16'd1),
        .y(PC_plus_1)
    );

	mux8 #(16) pc_mux(
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
	
	flopr pc_reg(
        .clk(clk),
        .reset(reset),
        .d(next_PC),
        .q(PC)
    );
	
	InstructionMem InstructionMemory(
        .PC(PC),
        .instruction(instruction)
    ); 
	
	flopenr #(16) RR(
        .clk(clk),
        .reset(reset),
        .en(Call_en),
        .d(PC_plus_1),
        .q(ret_addr)
    );	  
	
	assign j_target = {PC[15:9], instruction[11:3]};  
	
	Extender #(6) ext(
        .Ext_Imm(instruction[5:0]),
        .ExtOp(ExtOP),
        .extended(Ext_Imm)
    );
	
	adder branch_target(
        .a(PC),
        .b(Ext_Imm),
        .y(b_target)
    );
	
	mux2 #(3) mux_src1(
        .d0(instruction[11:9]),
        .d1(instruction[8:6]),
        .s(Src1),
        .y(Rs1)
    );


    mux4 #(3) mux_src2(
        .d0(instruction[8:6]),
        .d1(instruction[5:3]),
        .d2(instruction[11:9]),
        .d3(3'd0),
        .s(Src2),
        .y(Rs2)
    );

    mux2 #(3) mux_dest(
        .d0(instruction[8:6]),
        .d1(instruction[11:9]),
        .s(DestReg),
        .y(Rdest)
    );

    mux4 #(16) b_sel_mux(
        .d0(BusB),
        .d1(Ext_Imm),
        .d2(16'd1),
        .d3(16'd0),
        .s(SrcB),
        .y(b_sel)
    );	
	
	mux2 #(16) mux_compSrc(
        .d0(16'd0),
        .d1(BusB),
        .s(CompSrc),
        .y(compSecondOperand)
    );
	
	Comparator branch_forLoop_compare(
    .a(BusA),
	.b(compSecondOperand),
    .equal(b_flag)
    );	
	
	mux2_en #(16) mux_forLoop(
        .d0(BusB),
        .d1(PC_plus_1),
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
	
	
	ALU alu(
    .A(BusA), 
	.B(b_sel),
    .ALU_Ctrl(Alu_ctrl),
    .ALU_res(Alu_result),
    .zero(zero)
    );	
	
	assign opcode = instruction[15:12];
	assign func = instruction[2:0];
	
	DataMem data_memory(
    .clk(clk),
    .MemR (MemR),
    .MemWr(MemWr),
    .address(Alu_result),
    .Data_in(BusB),
    .Data_out(data_memory_out)
    );	 
	
	mux2 #(16) mux_writeBack(
        .d0(Alu_result),
        .d1(data_memory_out),
        .s(WBData),
        .y(BusW)
    ); 
    
endmodule 	

`timescale 1ns/1ps

module memory_wb_tb();
  
    reg clk;
    reg reset;
    reg Call_en;
    reg for_en;
    reg CompSrc;
    reg RegWr;
    reg Src1;
    reg DestReg;
    reg ExtOP;
    reg MemWr;
    reg MemR;
    reg WBData;
    reg [1:0] Src2;
    reg [1:0] SrcB;
    reg [2:0] PCSrc;
    reg [2:0] Alu_ctrl;

    
    wire b_flag;
    wire [3:0] opcode;
    wire [2:0] func;

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
        .MemWr(MemWr),
        .MemR(MemR),
        .WBData(WBData),
        .Src2(Src2),
        .SrcB(SrcB),
        .PCSrc(PCSrc),
        .Alu_ctrl(Alu_ctrl),
        .b_flag(b_flag),
        .opcode(opcode),
        .func(func)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        
        reset = 1;
        {Call_en, for_en, CompSrc, RegWr, Src1, DestReg, ExtOP, MemWr, MemR, WBData} = 0;
        {Src2, SrcB} = 0;
        {PCSrc, Alu_ctrl} = 0;

        #20 reset = 0;

        // Test 1: Load Word (lw)
        #10;
        RegWr = 1;
        MemR = 1;
        WBData = 1;
        Src1 = 0;
        DestReg = 0;
        ExtOP = 1;
        SrcB = 2'b01;
        Alu_ctrl = 3'b000;

        // Test 2: Store Word (sw)
        #10;
        RegWr = 0;
        MemR = 0;
        MemWr = 1;
        WBData = 0;
        Src1 = 0;
        ExtOP = 1;
        SrcB = 2'b01;
        Alu_ctrl = 3'b000;

        // Test 3: Add Immediate (addi)
        #10;
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
        #10;
        RegWr = 0;
        CompSrc = 1;
        Src1 = 0;
        Src2 = 2'b00;
        SrcB = 2'b01;
        PCSrc = 3'b001;
        Alu_ctrl = 3'b001;

        // Test 5: Jump (jmp)
        #10;
        CompSrc = 0;
        PCSrc = 3'b010;

        // Test 6: Call subroutine
        #10;
        Call_en = 1;
        PCSrc = 3'b011;

        // Test 7: For Loop
        #10;
        Call_en = 0;
        for_en = 1;
        PCSrc = 3'b100;
        Alu_ctrl = 3'b000;

        #20 $finish;
    end

    
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
        $monitor("BusA=%h BusB=%h BusW=%h",
                uut.BusA, uut.BusB, uut.BusW);
        $monitor("b_flag=%b branch_target=%h",
                b_flag, uut.b_target);
        
        $monitor("\n----------------------------------------");
    end

    
    initial begin
        $monitor("\nMemory Operation Details:");
        $monitor("Memory Address=%h", uut.Alu_result);
        $monitor("Memory Write Data=%h", uut.BusB);
        $monitor("Memory Read Data=%h", uut.data_memory_out);
        $monitor("Write Back Data=%h", uut.BusW);
    end

endmodule