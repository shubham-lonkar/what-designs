`timescale 1ns/1ps

module tb_branch_predictor_unit();
parameter BRANCH_PRED_METHOD = 1;
parameter DATA_WIDTH = 32;
parameter ADDRESS_BITS = 32;
reg clk, reset;
reg [31:0] pc;
reg instr_valid;
reg instruction;
reg actual_pred;
reg [31:0] update_pc, predicted_pc;
wire prediction;

branch_predictor_unit #(
    .BRANCH_PRED_METHOD(BRANCH_PRED_METHOD),
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRESS_BITS(ADDRESS_BITS)
    ) dut (
    .clk(clk),
    .reset(reset),
    .pc(pc),
    .instruction(instruction),  
    .instr_valid(instr_valid),
    .predicted_pc(predicted_pc),

    .prediction(prediction),
    .actual_pred(actual_pred),
    .update_pc(update_pc)
);

// Clock generation
always #5 clk = ~clk;

task print_state;
    input [31:0] current_pc;
    input [3:0] expected_index;
    begin
        $display("[%0t] PC=0x%h (Index %0d) | Pred=%b | State=%b",
               $time, current_pc, expected_index, 
              prediction, dut.genblk1.bp_2_bit.bht[expected_index]);
    end
endtask
integer i;
initial begin
    clk = 0;
    reset = 1;
    pc = 0;
    actual_pred = 0;
    update_pc = 0;
    instruction = 0;
    instr_valid = 0;
    predicted_pc = 0;
    
    // Reset sequence
    #20 reset = 0;
    $display("\n=== Initialization Test ===");
    // Verify all entries initialized to WNT (01)
    for(i=0; i<16; i=i+1) begin
        $display("BHT[%0d] = %b (Expected 01)", i, dut.genblk1.bp_2_bit.bht[i]);
    end

    // -------------------------------------------------
    // Test 1: Index 4 (pc[6:2] = 00110)
    // -------------------------------------------------
    $display("\n=== Test 1: Index 4 ===");
    // Initial state check
    pc = 32'h0000_0010; // Binary: ...0001_0000 → 0100 (index 4)
    #10;
    print_state(pc, 4);

    // Update to WT (Taken)
    @(posedge clk);
    update_pc = 32'h0000_0030;
    actual_pred = 1;
    @(posedge clk);
    actual_pred = 0;
    #10;
    pc = 32'h0000_0010;
    #10;
    print_state(pc, 4);

    // -------------------------------------------------
    // Test 2: Index 8 (pc[5:2] = 1000)
    // -------------------------------------------------
    $display("\n=== Test 2: Index 8 ===");
    pc = 32'h0000_0020; // Binary: ...0010_0000 → 1000 (index 8)
    #10;
    print_state(pc, 8);

    // Update to ST (Taken twice)
    repeat(2) begin
        @(posedge clk);
        update_pc = 32'h0000_0020;
        actual_pred = 1;
        @(posedge clk);
        actual_pred = 0;
        #10;
    end
    pc = 32'h0000_0020;
    #10;
    print_state(pc, 8);

    // -------------------------------------------------
    // Test 3: Aliasing Test (same index)
    // -------------------------------------------------
    $display("\n=== Test 3: Aliasing Test ===");
    // First PC: 0x0000_0014 → 0101 (index 5)
    pc = 32'h0000_0014; // Binary: ...0001_0100 → 0101 (index 5)
    #10;
    print_state(pc, 5);

    // Second PC: 0x0000_1014 → 0101 (index 5)
    pc = 32'h0000_1014; // Binary: ...1010_0100 → 0101 (index 5)
    #10;
    print_state(pc, 5);

    // Update via second PC
    @(posedge clk);
    update_pc = 32'h0000_1014;
    actual_pred = 1;
    @(posedge clk);
    actual_pred = 0;
    #10;

    // Check both PCs
    pc = 32'h0000_0014;
    #10;
    print_state(pc, 5);
    pc = 32'h0000_1014;
    #10;
    print_state(pc, 5);

    // -------------------------------------------------
    // Test 4: Boundary Indices
    // -------------------------------------------------
    $display("\n=== Test 4: Boundary Indices ===");
    // Index 0 (pc[5:2] = 0000)
    pc = 32'h0000_0000;
    #10;
    print_state(pc, 0);

    // Index 15 (pc[5:2] = 1111)
    pc = 32'h0000_003C; // Binary: ...0011_1100 → 1111 (index 15)
    #10;
    print_state(pc, 15);

    // Update index 15 to ST
    repeat(2) begin
        @(posedge clk);
        update_pc = 32'h0000_003C;
        actual_pred = 1;
        @(posedge clk);
        actual_pred = 0;
        #10;
    end
    pc = 32'h0000_003C;
    #10;
    print_state(pc, 15);

    // -------------------------------------------------
    // Final Checks
    // -------------------------------------------------
    #100;
    $display("\n=== Final State Snapshot ===");
    for(i=0; i<16; i=i+1) begin
        $display("BHT[%2d] = %b", i, dut.genblk1.bp_2_bit.bht[i]);
    end
    $finish;
end

endmodule
