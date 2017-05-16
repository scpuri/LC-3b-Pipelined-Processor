import lc3b_types::*;
`include "macros.sv"

// This is just really a basic direct-mapped cache
module BTB #(parameter size_bits = 3) (
	input clk,
	
	// Update the BTB
	input lc3b_word update_pc,
	input lc3b_word update_target,
	input logic [3:0] update_op,
	input logic update,
	
	// Read from the BTB
	input lc3b_word pc,
	output lc3b_word target,
	output logic [3:0] op,
	output logic valid
);

// Data array
lc3b_btb_entry data[2 ** size_bits];

// Initialize to 0
initial
begin
	for (int z = 0; z < 2 ** size_bits; z++) begin
		data[z] = '0;
	end
end

// Read from the BTB
always_comb
begin
	// Initials
	target = '0;
	op = 4'd0;
	valid = 1'b0;
	
	// Check if the direct mapped spot is in use by this pc
	if (data[pc[1 +: size_bits]].pc == pc) begin
		target = data[pc[1 +: size_bits]].target;
		op = data[pc[1 +: size_bits]].op;
		valid = data[pc[1 +: size_bits]].valid;
	end
end

// Update a value from the BTB
always_ff @(posedge clk)
begin
	if (update) begin
		// Write the new values
		data[update_pc[1 +: size_bits]].pc <= update_pc;
		data[update_pc[1 +: size_bits]].target <= update_target;
		data[update_pc[1 +: size_bits]].op <= update_op;
		data[update_pc[1 +: size_bits]].valid <= 1'b1;
	end
end

endmodule : BTB