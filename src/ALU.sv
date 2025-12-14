//----------------------------------------------------------------------------------------------------
// Filename: ALU.sv
// Author: Charles Bassani
// Description: Handles arithmetic operations
//----------------------------------------------------------------------------------------------------
`timescale 1ns/1ps

//----------------------------------------------------------------------------------------------------
// Module Declaration
//----------------------------------------------------------------------------------------------------
module ALU
(
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [4:0]  shamt,
    input  logic [3:0]  aluOp,
    input  logic        useSign,
    output logic        zero,
    output logic        overflow,
    output logic        cout,
    output logic [31:0] res
);

//----------------------------------------------------------------------------------------------------
// Module Registers
//----------------------------------------------------------------------------------------------------
logic msb_a;
logic msb_b;
logic msb_res;

//----------------------------------------------------------------------------------------------------
// Module Logic
//----------------------------------------------------------------------------------------------------
assign msb_a = a[31];
assign msb_b = b[31];

always @(res) begin
    msb_res = res[31];
end

always_comb begin
    zero = 1'b0;
    overflow = 1'b0;
    cout = 1'b0;
    res = 32'd0;
    if(useSign) begin
        case(aluOp)
            4'h0: begin //ADD
                {cout, res} = $signed(a) + $signed(b);
                overflow = (msb_a == msb_b) && (msb_res != msb_a);
            end
            4'h1: begin //SUB
                {cout, res} = $signed(a) - $signed(b); 
                overflow = (msb_a != msb_b) && (msb_res != msb_a);
            end
            4'h2: res = a & b; //AND
            4'h3: res = a | b; //OR
            4'h4: res = ~(a | b);//NOR
            4'h5: res = b <<< shamt; //SL
            4'h6: res = b >>> shamt; //SR
            4'h7: res = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; //SLT
        endcase
    end
    else begin
        case(aluOp)
            4'h0: begin //ADD
                {cout, res} = a + b;
                overflow = cout;
            end
            4'h1: begin //SUB
                {cout, res} = a - b;
                overflow = cout;
            end
            4'h2: res = a & b; //AND
            4'h3: res = a | b; //OR
            4'h4: res = ~(a | b);//NOR
            4'h5: res = b << shamt; //SL
            4'h6: res = b >> shamt; //SR
            4'h7: res = (a < b) ? 32'd1 : 32'd0; //SLT
        endcase
    end

    zero = (res == 0);
end

endmodule
