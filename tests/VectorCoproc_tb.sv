//----------------------------------------------------------------------------------------------------
// Filename: _tb.sv
// Author: Charles Bassani
// Description: 
//----------------------------------------------------------------------------------------------------
`timescale 1ns/1ps

//----------------------------------------------------------------------------------------------------
// Module Declaration
//----------------------------------------------------------------------------------------------------
module VectorCoproc_tb;

//----------------------------------------------------------------------------------------------------
// Test Registers
//----------------------------------------------------------------------------------------------------
    
// Clock and Reset
logic clk;
logic rst;

// Control Interface
logic        vec_we;
logic [2:0]  vec_addr_rd;
logic [2:0]  vec_addr_rs;
logic [2:0]  vec_addr_rt;

// ALU Controls
logic [3:0]  aluOp;
logic [4:0]  shamt;
logic        useSign;

// Scalar Interface
logic [31:0] scalar_val;
logic        use_scalar;

// Outputs
logic        vec_zero;

// ALU Opcode Constants
localparam ALU_ADD = 4'h0;
localparam ALU_SUB = 4'h1;
localparam ALU_AND = 4'h2;
localparam ALU_OR  = 4'h3;
localparam ALU_NOR = 4'h4;
localparam ALU_SL  = 4'h5;
localparam ALU_SR  = 4'h6;
localparam ALU_SLT = 4'h7;

//----------------------------------------------------------------------------------------------------
// Device Under Test
//----------------------------------------------------------------------------------------------------
VectorCoproc #(.LANES(4)) dut 
(
    .clk(clk),
    .rst(rst),
    .vec_we(vec_we),
    .vec_addr_rd(vec_addr_rd),
    .vec_addr_rs(vec_addr_rs),
    .vec_addr_rt(vec_addr_rt),
    .aluOp(aluOp),
    .shamt(shamt),
    .useSign(useSign),
    .scalar_val(scalar_val),
    .use_scalar(use_scalar),
    .vec_zero(vec_zero)
);

//----------------------------------------------------------------------------------------------------
// Waveform Generation
//----------------------------------------------------------------------------------------------------
initial begin
    $dumpfile("build/VectorCoproc_tb_wave.vcd");
    $dumpvars(0, VectorCoproc_tb);
end

//----------------------------------------------------------------------------------------------------
// Test Logic
//----------------------------------------------------------------------------------------------------
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

task load_vector_reg
(
    input int reg_idx, 
    input logic [31:0] val0, val1, val2, val3
);
    begin
        dut.vector_rf[reg_idx][0] = val0;
        dut.vector_rf[reg_idx][1] = val1;
        dut.vector_rf[reg_idx][2] = val2;
        dut.vector_rf[reg_idx][3] = val3;
        $display("Loaded $v%0d with {%0d, %0d, %0d, %0d}", reg_idx, val3, val2, val1, val0);
    end
endtask

task exec_vec_op
(
    input logic [3:0] op, 
    input int rd, rs, rt, 
    input logic use_sc = 0, 
    input logic [31:0] sc_val = 0
);
    begin
        @(negedge clk);
        vec_we      = 1;
        aluOp       = op;
        vec_addr_rd = rd;
        vec_addr_rs = rs;
        vec_addr_rt = rt;
        use_scalar  = use_sc;
        scalar_val  = sc_val;
        useSign     = 1;
        shamt       = 0;
        
        @(posedge clk);
        #1;
        vec_we = 0;
        
        $display("  Result: $v%0d = {%0d, %0d, %0d, %0d}", 
            rd,
            dut.vector_rf[rd][3], dut.vector_rf[rd][2], 
            dut.vector_rf[rd][1], dut.vector_rf[rd][0]);
    end
endtask
initial begin
    // Initialize Inputs
    rst = 1;
    vec_we = 0;
    vec_addr_rd = 0; vec_addr_rs = 0; vec_addr_rt = 0;
    aluOp = 0; shamt = 0; useSign = 1;
    scalar_val = 0; use_scalar = 0;

    #20;
    rst = 0;
    //Load vectors
    load_vector_reg(1, 10, 20, 30, 40); // $v1
    load_vector_reg(2, 1,  2,  3,  4);  // $v2

    //Vector-Vector ADD
    $display("\nVector-Vector ADD ($v3 = $v1 + $v2)");
    exec_vec_op(ALU_ADD, 3, 1, 2);

    //Vector-Scalar SUB
    $display("\nVector-Scalar SUB ($v4 = $v1 - 5)");    
    exec_vec_op(ALU_SUB, 4, 1, 0, 1, 32'd5);

    //Vector SLL
    $display("\nVector Shift Left ($v5 = $v2 << 1)");
    @(negedge clk);
    vec_we = 1; 
    aluOp = ALU_SL;
    vec_addr_rd = 5; 
    vec_addr_rt = 2;
    vec_addr_rs = 0;
    shamt = 1;
    use_scalar = 0;
    
    @(posedge clk); #1; vec_we = 0;
    $display("  Result: $v5 = {%0d, %0d, %0d, %0d}", 
        dut.vector_rf[5][3], dut.vector_rf[5][2], 
        dut.vector_rf[5][1], dut.vector_rf[5][0]);

    //Zero Check
    $display("\nZero Flag Check ($v6 = $v1 - $v1)");
    exec_vec_op(ALU_SUB, 6, 1, 1);

    $finish;
end

endmodule