module datapath (input clk, reset, 
	Call_en, kill, Src1, Src2, DestReg, 
	EMemMemWr,EMemMemR,EMemWBData,MemWbRegWr3,
	DERegWr1,EMemRegWr2,DEMemR,
	for_en, ExtOP, CompSrc, Alu_ctrl, 
	input [2:0] PCSrc, 
	input [1:0] SrcB,
	output B_flag_d_ex, stall,   
	output [3:0] Opcode, 
	output [2:0] Func
	);
	
	wire zero;
    wire [15:0] b_target, b_target_decode, j_target, ret_addr,for_addr, for_addr_d_ex;
    wire [15:0] PCplus1_F_d, inst_F_d;      
    reg [15:0] PC;
    wire [15:0] PC_plus_1, next_PC;
    wire [15:0] instruction,Inst,Inst_d_ex,Inst_ex_mem;
    wire [15:0] Ext_Imm;
    wire [2:0] Rs1, Rs2, Rdest;
    wire [15:0] B_sel, B_Sel_d_ex;
    wire [15:0] A,B;
	wire [15:0] BusA,BusB,BusW; 
	wire [15:0] Alu_result, Alu_result_ex_mem;
	wire [15:0] BusW_mem_wb; 
	wire [15:0] compSecondOperand;
	wire [15:0] data_memory_out;  
    wire [15:0] A_d_ex, B_d_ex, B_ex_mem; 
	wire [15:0] bubble ;
    wire [2:0] Rd1_d_ex, Rd2_ex_mem, Rd3_mem_wb ;
 	wire [1:0] FA , FB ;
	wire B_flag ;
	
	adder pc_plus_1(
        .a(PC),
        .b(16'd1),
        .y(PC_plus_1)
    );

    assign j_target = {PC[15:9],inst_F_d[11:3]};
	
    mux8 #(16) pc_mux(
        .d0(PC_plus_1),
        .d1(b_target_decode),
        .d2(j_target),
        .d3(ret_addr),
        .d4(for_addr_d_ex),
        .d5(16'd0),
        .d6(16'd0),
        .d7(16'd0),
        .s(PCSrc),
        .y(next_PC)
    );

    // Initial block for PC
    initial begin
        PC = 16'h0000;
    end
    
    // PC update logic
    always @(negedge clk or posedge reset) begin
        if (reset)
            PC <= 16'h0000;
        else
            PC <= stall ? PC : next_PC;
    end

    // Instruction memory read
    InstructionMem InstructionMemory(
        .PC(stall ? (PC - 16'd1) : PC),
        .instruction(Inst)
    ); 

	assign bubble = 16'b0000000000000000;

    mux2 #(16) mux_kill_inst(
        .d0(Inst),
        .d1(bubble),
        .s(kill),
        .y(instruction)
    );
    
   
    flopenr #(16) pcplus1_f_d(
        .clk(clk),
        .reset(reset),
        .en(!stall),
        .d(PC_plus_1),
        .q(PCplus1_F_d)
    );

    
    flopenr #(16) inst_f_d(
        .clk(clk),
        .reset(reset),
        .en(!stall),
        .d(instruction),
        .q(inst_F_d)
    );		
	
	assign Opcode = inst_F_d[15:12];
	assign Func = inst_F_d[3:0]; 
	
	hazard haz (Rd1_d_ex, Rd2_ex_mem, Rd3_mem_wb, Rs1, Rs2, DERegWr1, EMemRegWr2, MemWbRegWr3, DEMemR, FA, FB, stall );

    flopenr #(16) RR(
        .clk(clk),
        .reset(reset),
        .en(Call_en),
        .d(PC_plus_1),
        .q(ret_addr)
    );
    
    Extender #(6) ext(
        .Ext_Imm(inst_F_d[5:0]),
        .ExtOp(ExtOP),
        .extended(Ext_Imm)
    );
	
	
    adder branch_target(
        .a(PC),
        .b(Ext_Imm),
        .y(b_target)
    );
    
	flopenr #(16) B_target_reg_f_d(
        .clk(clk), .reset(reset),
        .en(1'b1),
        .d(b_target),
        .q(b_target_decode)
    );	
	
    mux2 #(3) mux_src1(
        .d0(inst_F_d[11:9]),
        .d1(inst_F_d[8:6]),
        .s(Src1),
        .y(Rs1)
    );


    mux4 #(3) mux_src2(
        .d0(inst_F_d[8:6]),
        .d1(inst_F_d[5:3]),
        .d2(inst_F_d[11:9]),
        .d3(16'd0),
        .s(Src2),
        .y(Rs2)
    );

    mux2 #(3) mux_dest(
        .d0(inst_F_d[8:6]),
        .d1(inst_F_d[11:9]),
        .s(DestReg),
        .y(Rdest)
    );

    mux4 #(16) b_sel_mux(
        .d0(B),
        .d1(Ext_Imm),
        .d2(16'd1),
        .d3(16'd0),
        .s(SrcB),
        .y(B_sel)
    );
	
	mux4 #(16) FA_mux(
        .d0(BusA),
        .d1(Alu_result_ex_mem),
        .d2(BusW_mem_wb),
        .d3(BusW),
        .s(FA),
        .y(A)
    );
	
	mux4 #(16) FB_mux(
        .d0(BusB),
        .d1(Alu_result_ex_mem),
        .d2(BusW_mem_wb),
        .d3(BusW),
        .s(FB),
        .y(B)
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
    .equal(B_flag)
    );	
	
	mux2_en #(16) mux_forLoop(
        .d0(B),
        .d1(PCplus1_F_d),
        .s(B_flag),
		.en(for_en),
        .y(for_addr)
    ); 
	
	flopenr #(16) for_reg_d_ex(
        .clk(clk), .reset(reset),
        .en(1'b1),
        .d(for_addr),
        .q(for_addr_d_ex)
    );
	
	RegFile register_file(
    .clk(clk),
    .RegWr(MemWbRegWr3),
    .Rs1(Rs1),
	.Rs2(Rs2),
	.Rdest(Rd3_mem_wb),
    .BusW(BusW),
    .BusA(BusA),
	.BusB(BusB)
    );	
	
	
    flopenr #(16) B_reg_d_ex(
        .clk(clk), .reset(reset),
        .en(1'b1),
        .d(B),
        .q(B_d_ex)
    );

    flopenr #(1) b_flag_reg_d_ex(
        .clk(clk), .reset(reset),
        .en(1'b1),
        .d(B_flag),
        .q(B_flag_d_ex)
    );
	
	flopenr #(16) b_sel_reg_d_ex(
        .clk(clk), .reset(reset),
        .en(1'b1),
        .d(B_sel),
        .q(B_Sel_d_ex)
    );
	
    flopenr #(16) inst_reg_d_ex(
        .clk(clk), .reset(reset),
        .en(1'b1),
        .d(inst_F_d),
        .q(Inst_d_ex)
    );


    flopenr #(3) rd1_reg_d_ex(
        .clk(clk), .reset(reset),
        .en(1'b1),
        .d(Rdest),
        .q(Rd1_d_ex)
    );

    flopenr #(16) A_reg_d_ex(
        .clk(clk), .reset(reset),
        .en(1'b1),
        .d(A),
        .q(A_d_ex)
    );

	ALU alu(
    .A(A_d_ex), 
	.B(B_Sel_d_ex),
    .ALU_Ctrl(Alu_ctrl),
    .ALU_res(Alu_result),
    .zero(zero)
    );	
	
	
	flopenr #(3) rd2_reg_ex_mem(
        .clk(clk), .reset(reset),
        .en(1'b1),
        .d(Rd1_d_ex),
        .q(Rd2_ex_mem)
    );	  
	
	
	flopenr #(16) B_reg_ex_mem(
        .clk(clk), .reset(reset),
        .en(1'b1),
        .d(B_d_ex),
        .q(B_ex_mem)
    );	 
	
	flopenr #(16) ALU_result_reg_ex_mem(
        .clk(clk), .reset(reset),
        .en(1'b1),
        .d(Alu_result),
        .q(Alu_result_ex_mem)
    );
	
	DataMem data_memory(
    .clk(clk),
    .MemR(EMemMemR),
    .MemWr(EMemMemWr),
    .address(Alu_result_ex_mem),
    .Data_in(B_ex_mem),
    .Data_out(data_memory_out)
    );	 
	
	mux2 #(16) mux_writeBack(
        .d0(Alu_result_ex_mem),
        .d1(data_memory_out),
        .s(EMemWBData),
        .y(BusW_mem_wb)
    ); 
	   
	
	flopenr #(3) rd3_reg_mem_wb(
        .clk(clk), .reset(reset),
        .en(1'b1),
        .d(Rd2_ex_mem),
        .q(Rd3_mem_wb)
    );	
	
	flopenr #(16) BusW_reg_mem_wb(
        .clk(clk), .reset(reset),
        .en(1'b1),
        .d(BusW_mem_wb),
        .q(BusW)
    );	   
	
endmodule 		

module hazard(input [2:0] Rd1, Rd2, Rd3, Rs1, Rs2,
              input RegWr1,RegWr2,RegWr3,MemREx,
              output reg [1:0] FA, FB,
              output reg stall);

 	always @(*)
		begin
    		
	
			if (Rs1 != 0 && Rs1 == Rd1 && RegWr1)
				FA = 2'b01 ;
        		else if (Rs1 != 0 && Rs1 == Rd2 && RegWr2)
				FA = 2'b10 ; 
			else if ( Rs1 != 0 && Rs1 == Rd3 && RegWr3)
				FA = 2'b11 ;	
			else 
				FA = 2'b00 ;	
				
				
			if (Rs2 != 0 && Rs2 == Rd1 && RegWr1)
				FB = 2'b01 ;
        		else if (Rs2 != 0 && Rs2 == Rd2 && RegWr2)
				FB = 2'b10 ;
			else if ( Rs2 != 0 && Rs2 == Rd3 && RegWr3)
				FB = 2'b11 ;
			else
				FB = 2'b00 ;
	
			stall = (FA == 1 || FB == 1) && MemREx  ;  
			
		end

 
endmodule