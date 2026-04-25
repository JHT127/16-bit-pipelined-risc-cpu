module CPU (
    input clk,
    input reset,
    output [31:0] total_instructions,
    output [31:0] load_instructions,
    output [31:0] store_instructions,
    output [31:0] alu_instructions,
    output [31:0] control_instructions,
    output [31:0] clock_cycles,
    output [31:0] stall_cycles
);
    wire Src1, Src2, DestReg, call_en, for_en, CompSrc, kill, ExtOP;
    wire [1:0] SrcB;
    wire [2:0] ALU_Ctrl, PCSrc;
    wire DERegWr1, DEMemWr, DEMemR, DEWBData;
    wire EMemRegWr2, EMemMemWr, EMemMemR, EMemWBData, MemWbRegWr3;
    wire B_flag_d_ex, stall;
    wire [3:0] Opcode;
    wire [2:0] Func;

    datapath datapath_inst (
        .clk(clk),
        .reset(reset),
        .Call_en(call_en),
        .kill(kill),
        .Src1(Src1),
        .Src2(Src2),
        .DestReg(DestReg),
        .EMemMemWr(EMemMemWr),
        .EMemMemR(EMemMemR),
        .EMemWBData(EMemWBData),
        .MemWbRegWr3(MemWbRegWr3),
        .DERegWr1(DERegWr1),
        .EMemRegWr2(EMemRegWr2),
        .DEMemR(DEMemR),
        .for_en(for_en),
        .ExtOP(ExtOP),
        .CompSrc(CompSrc),
        .Alu_ctrl(ALU_Ctrl),
        .PCSrc(PCSrc),
        .SrcB(SrcB),
        .B_flag_d_ex(B_flag_d_ex),
        .stall(stall),
        .Opcode(Opcode),
        .Func(Func)
    );

    controller controller_inst (
        .opcode(Opcode),
        .func(Func),
        .b_flag(B_flag_d_ex),
        .stall(stall),
        .Src1(Src1),
        .Src2(Src2),
        .DestReg(DestReg),
        .call_en(call_en),
        .for_en(for_en),
        .CompSrc(CompSrc),
        .kill(kill),
        .ExOp(ExtOP),
        .clk(clk),
        .reset(reset),
        .SrcB(SrcB),
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
        .stall_cycles(stall_cycles));
endmodule