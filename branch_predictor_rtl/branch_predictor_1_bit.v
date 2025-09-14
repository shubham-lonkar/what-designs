module branch_predictor_1_bit #(
    parameter DATA_WIDTH        = 32,
    parameter ADDRESS_BITS      = 32,
    parameter BHT_DEPTH         = 1024,
    parameter LOG2_BHT_DEPTH    = $clog2(BHT_DEPTH)
)
(
    input                       clk,
    input                       reset,
    input  [ADDRESS_BITS-1:0]   PC,  
    input  [DATA_WIDTH-1:0]     instruction,  
    input                       instr_valid,
    input                       mispred,
    input                       actual_pred,
    output                      prediction,
    
    output [ADDRESS_BITS-1:0]   predicted_pc,
    input  [6:0]                update_opcode,
    input  [ADDRESS_BITS-1:0]   update_pc  
);

    // FSM States
    localparam NT   = 1'b0; 
    localparam T    = 1'b1; 

    reg  bht [BHT_DEPTH-1:0];
    wire [LOG2_BHT_DEPTH-1:0] index             = PC[LOG2_BHT_DEPTH+1:2];
    wire [LOG2_BHT_DEPTH-1:0] update_index      = update_pc[LOG2_BHT_DEPTH+1:2];
    wire [6:0] opcode                           = instruction [6:0];

	assign prediction = (instr_valid && opcode == 'b1100011) ? bht[index] : 1'b0;
    integer i;
    ///////////////////////////////////////////////////////////
    // Logic to update the BHT
    /*always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < BHT_DEPTH; i = i + 1)
                bht[i] <= WNT;
        end else if (update_opcode == 'b1100011) begin
            case (bht[update_index])
                SNT: bht[update_index] <= (actual_pred) ? WNT : SNT;
                WNT: bht[update_index] <= (actual_pred) ? WT  : SNT;
                WT:  bht[update_index] <= (actual_pred) ? ST  : WNT;
                ST:  bht[update_index] <= (actual_pred) ? ST  : WT;
            endcase
        end
    end*/

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < BHT_DEPTH; i = i + 1)
               bht[i] <= NT;
        end else if (update_opcode == 'b1100011) begin
            if (bht[update_index] != actual_pred) begin
               bht[update_index] <= ~bht[update_index]; 
			end 
            else begin
				bht[update_index] <= bht[update_index]; 
			end
        end
    end
    ////////////////////////////////////////////////////////////
    // predicted PC logic
    wire[6:0]  s_imm_msb;
    wire[4:0]  s_imm_lsb;
    wire[12:0] sb_imm_orig;
    wire [31:0] sb_imm_extended;

    assign s_imm_msb  = instruction[31:25];    
    assign s_imm_lsb  = instruction[11:7];
    assign sb_imm_orig = {s_imm_msb[6],s_imm_lsb[0],s_imm_msb[5:0],s_imm_lsb[4:1],1'b0};

    assign sb_imm_extended     = {{DATA_WIDTH-13{sb_imm_orig[12]}}, sb_imm_orig};
    assign predicted_pc = PC + sb_imm_extended; 

endmodule
