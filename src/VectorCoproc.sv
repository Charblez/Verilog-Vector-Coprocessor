//----------------------------------------------------------------------------------------------------
// Filename: VectorCoproc.sv
// Author: Charles Bassani
// Description: Implementation of a basic vector coprocessor
//----------------------------------------------------------------------------------------------------
`timescale 1ns/1ps

//----------------------------------------------------------------------------------------------------
// Module Declaration
//----------------------------------------------------------------------------------------------------
module VectorCoproc
#(
    parameter LANES = 4,
    parameter REG_COUNT = 8
)
(
    input  logic        clk,
    input  logic        rst,
    
    // --- Control Signals ---
    input  logic        vec_we,
    input  logic [2:0]  vec_addr_rd,
    input  logic [2:0]  vec_addr_rs,
    input  logic [2:0]  vec_addr_rt,
    
    // --- Operation Signals ---
    input  logic [3:0]  aluOp,
    input  logic [4:0]  shamt,
    input  logic        useSign,

    // --- Scalar Mode ---
    input  logic [31:0] scalar_val,   
    input  logic        use_scalar,

    // --- Outputs ---
    output logic        vec_zero 
);  

//----------------------------------------------------------------------------------------------------
// Module Registers
//----------------------------------------------------------------------------------------------------
logic [LANES-1:0][31:0] vector_rf [0:REG_COUNT-1];
logic [LANES-1:0][31:0] read_data_a;
logic [LANES-1:0][31:0] read_data_b;
logic [LANES-1:0][31:0] write_data;
logic [LANES-1:0][31:0] lane_results;
logic [LANES-1:0]       lane_zeros;
logic [LANES-1:0]       lane_overflows;
logic [LANES-1:0]       lane_couts;

//----------------------------------------------------------------------------------------------------
// Module Logic
//----------------------------------------------------------------------------------------------------
assign write_data = lane_results; 
assign vec_zero = &lane_zeros; 

// Reading logic (Combinational)
always_comb begin
    read_data_a = vector_rf[vec_addr_rs];
    read_data_b = vector_rf[vec_addr_rt];
end

// Writing logic (Sequential)
always_ff @(posedge clk or posedge rst) begin
    if(rst) for(int i = 0; i < REG_COUNT; ++i) vector_rf[i] <= 0;
    else if(vec_we) vector_rf[vec_addr_rd] <= write_data;
end

genvar i;
generate
    for(i = 0; i < LANES; i++) begin : lanes
        ALU alu_inst 
        (
            .a          (read_data_a[i]),
            .b          (use_scalar ? scalar_val : read_data_b[i]),
            .shamt      (shamt),
            .aluOp      (aluOp),
            .useSign    (useSign),
            .zero       (lane_zeros[i]),
            .overflow   (lane_overflows[i]),
            .cout       (lane_couts[i]),
            .res        (lane_results[i])
        );
    end
endgenerate

endmodule