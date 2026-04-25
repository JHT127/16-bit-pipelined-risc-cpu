					  
module DataMem (
    input wire clk,
    input wire MemR,
    input wire MemWr,
    input wire [15:0] address,
    input wire [15:0] Data_in,
    output reg [15:0] Data_out
);
                                                          
    reg [15:0] memory [65535:0];  

    initial begin
        $readmemh("data_mem.dat", memory);
    end

    reg [15:0] last_read_data;  // Debug signal

    always @(posedge clk) begin
        if (MemWr) begin
            memory[address] <= Data_in;
            $display("Memory Write Operation:");
            $display("Address: %h", address);
            $display("Data: %h", Data_in);
        end
    end

    always @(*) begin
        if (MemR) begin
            Data_out = memory[address];
            $display("Memory Read Operation:");
            $display("Address: %h", address);
            $display("Data: %h", Data_out);
        end
        else
            Data_out = 16'hz;  
    end

endmodule

//////////////////////////////////////////////////

module InstructionMem (
    input wire [15:0] PC,
    output reg [15:0] instruction
);

    reg [15:0] memory [65535:0];  

    initial begin
        $readmemh("program.dat", memory);
        $display("Instruction Memory Contents:");
        $display("memory[0] = %h (%s)", memory[0], decode_instruction(memory[0]));
        $display("memory[1] = %h (%s)", memory[1], decode_instruction(memory[1]));
        $display("memory[2] = %h (%s)", memory[2], decode_instruction(memory[2]));
        $display("memory[3] = %h (%s)", memory[3], decode_instruction(memory[3]));
    end

    always @(*) begin
        instruction = memory[PC];
        $display("Fetching instruction at PC=%h: %h (%s)", 
            PC, instruction, decode_instruction(instruction));
    end

endmodule



