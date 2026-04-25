`timescale 1ns/1ps

module CPU_tb();
    // Test bench signals
    reg clk;
    reg reset;
    
    // Performance monitoring outputs
    wire [31:0] total_instructions;
    wire [31:0] load_instructions;
    wire [31:0] store_instructions;
    wire [31:0] alu_instructions;
    wire [31:0] control_instructions;
    wire [31:0] clock_cycles;
    wire [31:0] stall_cycles;
    
    // Instantiate the CPU
    CPU cpu_inst (
        .clk(clk),
        .reset(reset),
        .total_instructions(total_instructions),
        .load_instructions(load_instructions),
        .store_instructions(store_instructions),
        .alu_instructions(alu_instructions),
        .control_instructions(control_instructions),
        .clock_cycles(clock_cycles),
        .stall_cycles(stall_cycles)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Add this function to your testbench
    function string decode_instruction;
        input [15:0] inst;
        reg [3:0] opcode;
        reg [2:0] rd, rs, rt, func;
        reg [5:0] imm;
        reg [8:0] offset;
        string inst_str;
        begin
            opcode = inst[15:12];
            rd = inst[11:9];
            rs = inst[8:6];
            rt = inst[5:3];
            func = inst[2:0];
            imm = inst[5:0];
            offset = inst[11:3];
            
            case(opcode)
                4'b0100: begin // LW
                    inst_str = $sformatf("LW R%0d, %0d(R%0d)", rd, imm, rs);
                end
                4'b0101: begin // SW
                    inst_str = $sformatf("SW R%0d, %0d(R%0d)", rd, imm, rs);
                end
                4'b0000: begin // R-type
                    case(func)
                        3'b000: inst_str = $sformatf("AND R%0d, R%0d, R%0d", rd, rs, rt);
                        3'b001: inst_str = $sformatf("ADD R%0d, R%0d, R%0d", rd, rs, rt);
                        3'b010: inst_str = $sformatf("SUB R%0d, R%0d, R%0d", rd, rs, rt);
                        3'b011: inst_str = $sformatf("SLL R%0d, R%0d, R%0d", rd, rs, rt);
                        3'b100: inst_str = $sformatf("SRL R%0d, R%0d, R%0d", rd, rs, rt);
                        default: inst_str = $sformatf("Unknown R-type: %h", inst);
                    endcase
                end
                4'b0010: inst_str = $sformatf("ANDI R%0d, R%0d, %0d", rt, rs, imm);
                4'b0011: inst_str = $sformatf("ADDI R%0d, R%0d, %0d", rt, rs, imm);
                4'b0110: inst_str = $sformatf("BEQ R%0d, R%0d, %0d", rs, rt, imm);
                4'b0111: inst_str = $sformatf("BNE R%0d, R%0d, %0d", rs, rt, imm);
                4'b1000: inst_str = $sformatf("FOR R%0d, R%0d", rs, rt);
                4'b0001: begin // J-type
                    case(func)
                        3'b000: inst_str = $sformatf("JMP %0d", offset);
                        3'b001: inst_str = $sformatf("CALL %0d", offset);
                        3'b010: inst_str = "RET";
                        default: inst_str = $sformatf("Unknown J-type: %h", inst);
                    endcase
                end
                default: inst_str = $sformatf("Unknown instruction: %h", inst);
            endcase
            decode_instruction = inst_str;
        end
    endfunction
    
    // Monitor for instruction execution
    always @(posedge clk) begin
        if (!reset) begin
            $display("\nTime=%0t ns: PC=0x%h", $time, cpu_inst.datapath_inst.PC);
            
            // Fetch Stage Debug
            $display("\nFetch Stage:");
            $display("PC = %h", cpu_inst.datapath_inst.PC);
            $display("Instruction = %h (%s)", 
                cpu_inst.datapath_inst.instruction,
                decode_instruction(cpu_inst.datapath_inst.instruction));
            $display("Next_PC = %h", cpu_inst.datapath_inst.next_PC);
            
            // Decode Stage Debug
            $display("\nDecode Stage:");
            $display("Instruction = %h (%s)", 
                cpu_inst.datapath_inst.inst_F_d,
                decode_instruction(cpu_inst.datapath_inst.inst_F_d));
            $display("Rs1 = %h", cpu_inst.datapath_inst.Rs1);
            $display("Rs2 = %h", cpu_inst.datapath_inst.Rs2);
            $display("Rdest = %h", cpu_inst.datapath_inst.Rdest);
            $display("Control Signals:");
            $display("RegWr=%b, MemR=%b, MemW=%b", 
                cpu_inst.controller_inst.DERegWr1,
                cpu_inst.controller_inst.DEMemR,
                cpu_inst.controller_inst.DEMemWr);
            
            // Execute Stage Debug
            $display("\nExecute Stage:");
            $display("ALU_A = %h", cpu_inst.datapath_inst.A);
            $display("ALU_B = %h", cpu_inst.datapath_inst.B);
            $display("ALU_Result = %h", cpu_inst.datapath_inst.Alu_result);
            
            // Memory Stage Debug
            $display("\nMemory Stage:");
            $display("Address = %h", cpu_inst.datapath_inst.Alu_result_ex_mem);
            $display("MemRead = %b", cpu_inst.controller_inst.EMemMemR);
            $display("MemWrite = %b", cpu_inst.controller_inst.EMemMemWr);
            $display("Write_Data = %h", cpu_inst.datapath_inst.B_ex_mem);
            
            // Writeback Stage Debug
            $display("\nWriteback Stage:");
            $display("WriteBack_Data = %h", cpu_inst.datapath_inst.BusW);
            $display("WriteBack_Reg = %d", cpu_inst.datapath_inst.Rd3_mem_wb);
            $display("RegWrite = %b", cpu_inst.controller_inst.MemWbRegWr3);
            
            // Register File Status
            $display("\nRegister File Status:");
            for (integer i = 0; i < 8; i = i + 1)
                $display("R%0d = 0x%h", i, cpu_inst.datapath_inst.register_file.registers[i]);
            
            // Pipeline Register Contents
            $display("\nPipeline Registers:");
            $display("IF/ID: PC=%h, Inst=%h", 
                cpu_inst.datapath_inst.PCplus1_F_d,
                cpu_inst.datapath_inst.inst_F_d);
            $display("ID/EX: Rs1=%h, Rs2=%h, Rd=%h", 
                cpu_inst.datapath_inst.Rs1,
                cpu_inst.datapath_inst.Rs2,
                cpu_inst.datapath_inst.Rd1_d_ex);
            $display("EX/MEM: ALUResult=%h, WriteReg=%h",
                cpu_inst.datapath_inst.Alu_result_ex_mem,
                cpu_inst.datapath_inst.Rd2_ex_mem);
            $display("MEM/WB: WriteData=%h, WriteReg=%h",
                cpu_inst.datapath_inst.BusW,
                cpu_inst.datapath_inst.Rd3_mem_wb);
            
            $display("----------------------------------------\n");
        end
    end

    // Test stimulus
    initial begin
        // Initialize
        reset = 1;
        clk = 0;
        
        // Hold in reset for 4 clock edges
        repeat(4) @(posedge clk);
        
        // Release reset synchronously
        @(negedge clk) reset = 0;
        
        // Wait for pipeline to fill and execute instructions
        repeat(12) @(posedge clk);
        
        // Display final register values
        $display("\nFinal Register Values:");
        for (integer i = 0; i < 8; i = i + 1)
            $display("R%0d = 0x%h", i, cpu_inst.datapath_inst.register_file.registers[i]);
            
        // Display final memory values
        $display("\nFinal Memory Values (first 4 words):");
        for (integer i = 0; i < 4; i = i + 1)
            $display("memory[%0d] = 0x%h", i, cpu_inst.datapath_inst.data_memory.memory[i]);
        
        // Display performance metrics
        $display("\nPerformance Metrics:");
        $display("Total Instructions: %0d", total_instructions);
        $display("Load Instructions: %0d", load_instructions);
        $display("Store Instructions: %0d", store_instructions);
        $display("ALU Instructions: %0d", alu_instructions);
        $display("Control Instructions: %0d", control_instructions);
        $display("Clock Cycles: %0d", clock_cycles);
        $display("Stall Cycles: %0d", stall_cycles);
        
        #100 $finish;
    end
    
    // Timeout watchdog
    initial begin
        #100000 // Adjust timeout value as needed
        $display("Simulation timeout!");
        $finish;
    end
    
endmodule