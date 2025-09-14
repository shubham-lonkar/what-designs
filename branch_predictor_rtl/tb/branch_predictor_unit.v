module branch_predictor_unit #(
    parameter TWO_BIT               = 2,
    parameter ONE_BIT               = 1,
    parameter BRANCH_PRED_METHOD    = ONE_BIT,
    parameter BHT_DEPTH             = 32,
    parameter DATA_WIDTH            = 32,
    parameter ADDRESS_BITS          = 32
)   (
    input                           clk,
    input                           reset,
    input  [ADDRESS_BITS-1:0]       pc,         // Branch instruction address
    output                          prediction, // 1: predict taken, 0: not taken
    input  [DATA_WIDTH-1:0]         instruction,  
    input                           instr_valid,
    input                           actual_pred,
    input                           mispred,
    output [ADDRESS_BITS-1:0]       predicted_pc,
    input  [6:0]                    update_opcode,
    input  [ADDRESS_BITS-1:0]       update_pc  // PC of branch to update
);

generate
    if (BRANCH_PRED_METHOD == ONE_BIT) begin
        branch_predictor_1_bit # (
            .DATA_WIDTH(DATA_WIDTH),
            .BHT_DEPTH(BHT_DEPTH),
            .ADDRESS_BITS(ADDRESS_BITS)
        )   branch_predictor_1_bit  (
            .clk(clk),
            .reset(reset),
            .PC(pc),         
            .prediction(prediction), // 1: predict taken, 0: not taken
            .mispred(mispred),
            .update_pc(update_pc),  // PC of branch to update
            .update_opcode(update_opcode),
            .instruction(instruction),  
            .actual_pred(actual_pred),
            .instr_valid(instr_valid),
            .predicted_pc(predicted_pc)
        );
    end
    else if (BRANCH_PRED_METHOD == TWO_BIT) begin
        branch_predictor_2_bit # (
            .DATA_WIDTH(DATA_WIDTH),
            .BHT_DEPTH(BHT_DEPTH),
            .ADDRESS_BITS(ADDRESS_BITS)
        )   branch_predictor_2_bit  (
            .clk(clk),
            .reset(reset),
            .PC(pc),         
            .prediction(prediction), // 1: predict taken, 0: not taken
            .mispred(mispred),
            .update_pc(update_pc),  // PC of branch to update
            .update_opcode(update_opcode),
            .instruction(instruction),  
            .actual_pred(actual_pred),
            .instr_valid(instr_valid),
            .predicted_pc(predicted_pc)
        );
    end
endgenerate

endmodule