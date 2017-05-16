import lc3b_types::*;
`include "macros.sv"

// size_bits is the number of counter entries in bits (3 bits = 8 entries)
// offset_bits is how many bits to offset the pc when computing things
// (1 means instead of pc[value:0], do pc[value+1:1]})
module branch_predictor #(parameter size_bits = 3, parameter history_size_bits = 3,
	parameter offset_bits = 1, parameter btb_size = 8)(
	input clk,
		
	// For when a branch was resolved,
	input update,										// A branch was resolved
	input update_is_branch,							// Update is a conditional branch (if not only update BTB)
	input lc3b_word update_pc,						// The PC for the resolved branch
	input update_taken,								// Whether or not that resolved branch was taken
	input lc3b_word update_target,				// Where the branch was resolved to be taken
	input logic [3:0] update_op,					// BR, JMP, JSR? etc
	
	
	// For when testing a branch
	input lc3b_word pc,								// PC of current instruction
	output logic is_control_flow,					// Whether this current instruction is a branch
	output logic should_take,						// Whether we should take this branch
	output lc3b_word address						// Computed address
);

logic [3:0] btb_op;
// BTB
BTB branch_target_buffer(
	.clk(clk),
	.update_pc(update_pc),
	.update_target(update_target),
	.update_op(update_op),
	.update(update),
	.pc(pc),
	.target(address),
	.valid(is_control_flow),
	.op(btb_op)
);

// PC[history_size_bits+offset_bits-1:offset_bits] indexes into a history table,
// then xor(PC[HISTORY_SIZE+offset_bits-1:offset_bits], history), which then indexes into a
// 2 Bit Saturating Counter
`define STRONGLY_TAKEN 		2'd3
`define WEAKLY_TAKEN			2'd2
`define WEAKLY_NOT_TAKEN	2'd1
`define STRONGLY_NOT_TAKEN	2'd0

// History table
logic [`HISTORY_WIDTH-1:0] history_table[2 ** history_size_bits];

// Counter table
logic [1:0] counter_table[2 ** history_size_bits];

// Initialize all counters to be WEAKLY_TAKEN
initial
begin
	for (int z = 0; z < 2 ** history_size_bits; z++) begin
		history_table[z] = '0;
		counter_table[z] = `WEAKLY_TAKEN;
	end
end

// Intermediates
logic [`HISTORY_WIDTH-1:0] history_index;
logic [`HISTORY_WIDTH-1:0] counter_index;

// Fill out whether we should take a branch based on the history and pc
always_comb
begin
	// Compute the two level indexes
	history_index = pc[offset_bits +: history_size_bits];
	counter_index = pc[offset_bits +: `HISTORY_WIDTH] ^ history_table[history_index];
	
	// Tell us the result (or auto take if we have a valid btb entry and its not a branch)
	should_take = (counter_table[counter_index] >= `WEAKLY_TAKEN) ||
		(is_control_flow && (btb_op != `CF_BRANCH));
end

// Intermediates
logic [`HISTORY_WIDTH-1:0] update_h_index;
logic [`HISTORY_WIDTH-1:0] update_c_index;

assign update_h_index = update_pc[offset_bits +: history_size_bits];
assign update_c_index = update_pc[offset_bits +: `HISTORY_WIDTH] ^ history_table[update_h_index];

// An update has occured
always_ff @(posedge clk)
begin
	if (update && update_is_branch) begin
		// If the update is a branch, update the counter it corresponds to
		if (update_taken && counter_table[update_c_index] != `STRONGLY_TAKEN) begin
			counter_table[update_c_index] = counter_table[update_c_index] + 2'd1;
		end else if (!update_taken && counter_table[update_c_index] != `STRONGLY_NOT_TAKEN) begin
			counter_table[update_c_index] = counter_table[update_c_index] - 2'd1;
		end
		// Update the history table too
		history_table[update_h_index] = (history_table[update_h_index] << 1) | update_taken;
	end
end

endmodule : branch_predictor