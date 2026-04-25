module ALU (
    input wire [15:0] A, B,
    input wire [2:0] ALU_Ctrl,
    output reg [15:0] ALU_res,
    output wire zero
);

    always @(*) begin
        case(ALU_Ctrl)
            3'b000: ALU_res = A & B;    // AND
            3'b001: ALU_res = A + B;    // ADD
            3'b010: ALU_res = A - B;    // SUB
            3'b011: ALU_res = A << B;   // SLL
            3'b100: ALU_res = A >> B;   // SRL
            default: ALU_res = 16'b0;
        endcase
    end

    assign zero = (ALU_res == 16'b0);

endmodule

////////////////////////////////////////////////

module RegFile(
    input wire clk,
    input wire RegWr,
    input wire [2:0] Rs1, Rs2, Rdest,
    input wire [15:0] BusW,
    output wire [15:0] BusA, BusB
);
    reg [15:0] registers[7:0];

    // Initialize all registers to 0
    integer i;
    initial begin
        for (i = 0; i < 8; i = i + 1)
            registers[i] = 16'h0000;
    end

    always @(negedge clk) begin
        if (RegWr && Rdest != 3'b0) begin
            registers[Rdest] <= BusW;
            $display("Register Write: R%0d = %h", Rdest, BusW);
        end
    end

    assign BusA = (Rs1 != 0) ? registers[Rs1] : 16'b0;
    assign BusB = (Rs2 != 0) ? registers[Rs2] : 16'b0;

    // Add debug prints for register reads
    always @(*) begin
        if (Rs1 != 0)
            $display("Register Read Rs1: R%0d = %h", Rs1, registers[Rs1]);
        if (Rs2 != 0)
            $display("Register Read Rs2: R%0d = %h", Rs2, registers[Rs2]);
    end

endmodule

////////////////////////////////////////////////

module adder(input  [15:0] a, b,
             output [15:0] y);

  assign y = a + b;
endmodule  

///////////////////////////////////////////////

module Comparator(
    input wire [15:0] a, b,
    output wire equal
);
    assign equal = (a == b);
endmodule

////////

module Extender #(parameter WIDTH = 6)(
    input wire [WIDTH-1:0] Ext_Imm,
    input wire ExtOp,
    output wire [15:0] extended
);
    assign extended = ExtOp ? 
                     {{(16-WIDTH){1'b0}}, Ext_Imm} : 
                     {{(16-WIDTH){Ext_Imm[WIDTH-1]}}, Ext_Imm};
endmodule		

/////////////////		

module flopr #(parameter WIDTH = 16) // register with reset
              (input                  clk, reset,
               input      [WIDTH-1:0] d, 
               output reg [WIDTH-1:0] q);

  always @(negedge clk, posedge reset)
    if (reset) q <= 0;
    else       q <= d;
endmodule

//////////

module flopenr #(parameter WIDTH = 16)
                (input                  clk, reset,
                 input                  en,
                 input      [WIDTH-1:0] d, 
                 output reg [WIDTH-1:0] q);
 
  always @(negedge clk, posedge reset)
    if      (reset) q <= 0;
    else if (en)    q <= d;
endmodule 

///////////

module RR (
    input wire clk,          
    input wire en,           
    input wire [15:0] PC_1,  
    output reg [15:0] RET    
);

    
    always @(posedge clk) begin
        if (en) begin
            RET <= PC_1;    
        end
    end

endmodule	

/////////
 
module mux2 #(parameter WIDTH = 16)
             (input  [WIDTH-1:0] d0, d1, 
              input              s, 
              output [WIDTH-1:0] y);

  assign y = s ? d1 : d0; 
endmodule

/////////////////////////

module mux4 #(parameter WIDTH = 16)
             (input  [WIDTH-1:0] d0, d1, d2, d3,
              input  [1:0]       s, 
              output [WIDTH-1:0] y);

  assign y = s[1] ? (s[0] ? d3 : d2) : (s[0] ? d1 : d0); 
endmodule  

//////////////////////

module mux8 #(parameter WIDTH = 16)
             (input  [WIDTH-1:0] d0, d1, d2, d3, d4, d5, d6, d7,
              input  [2:0]       s, 
              output [WIDTH-1:0] y);
  assign y = s[2] ? (s[1] ? (s[0] ? d7 : d6) : (s[0] ? d5 : d4)) :
                    (s[1] ? (s[0] ? d3 : d2) : (s[0] ? d1 : d0));
endmodule	

//////////////////////////

module mux2_en #(parameter WIDTH = 16)
             (input  [WIDTH-1:0] d0, d1,
              input              s,
              input              en,
              output [WIDTH-1:0] y);
    
    assign y = en ? (s ? d1 : d0) : 'bz;
endmodule