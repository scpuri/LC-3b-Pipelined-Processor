import lc3b_types::*;
`include "macros.sv"

module control_flow_rs #(parameter size=`NUM_CONTROL_FLOW_STATIONS)(
	input clk,
	
	input logic ld_reservations[size-1:0],
	output logic reservations_available[size-1:0],
	
	output logic[size-1:0] complete,
	input logic[31:0] selection,
	input sel_load,
	
	input lc3b_word rob_commit_value,
	input rob_commit,
	input lc3b_rob_id rob_commit_pos,
	
	input logic[3:0] op_in,
	input lc3b_word vj_in, vk_in,
	input lc3b_rob_id qj_in, qk_in,
	input lc3b_rob_id dest_in,
	input lc3b_word pc_in,
	input logic prediction_in,
	
	lc3b_cdb data_bus,
	lc3b_cdb data_bus_out,
	output logic finish,
	
	// Outputs to fetch
	output logic cf_update,
	output lc3b_word cf_pc,
	output lc3b_word cf_target,
	output logic [3:0] cf_op,
	output logic cf_taken,
	
	input flush
);

// Finds the corresponding local reservation station
function int find_loaded_rs(logic ld_reservations[size-1:0]);

for (int z = 0; z < size; z++) begin
	if (ld_reservations[z])
		return z + 1;
end

return res_invalid;

endfunction

lc3b_rs_id index;
logic[size-1:0] ready;
lc3b_word outputs[size];
lc3b_word new_pcs[size];
lc3b_word targets[size];
logic pc_taken[size];
logic predictions[size];
lc3b_rs_entry data[size];
lc3b_rs_id finish_index;
logic load_res;

assign index = lc3b_rs_id'(find_loaded_rs(ld_reservations) - 1);
assign load_res = find_loaded_rs(ld_reservations) != int'(res_invalid);

// Extend the Reservation Station entry with predictions
initial
begin
	for (int z = 0; z < size; z++) begin
		predictions[z] = 1'd0;
	end
end

always_ff @(posedge clk)
begin
	if (load_res) begin
		predictions[index] = prediction_in;
	end
	
	if (flush) begin
		for (int z = 0; z < size; z++) begin
			predictions[z] = 1'd0;
		end
	end
end

reservation_station #(`NUM_CONTROL_FLOW_STATIONS) cf_station (
	.*,
	.load(load_res)
);

// Mark selected the station as finished
always_comb
begin
	finish_index = lc3b_rs_id'(selection - int'(res_cf_1));
	finish = sel_load && (selection >= int'(res_cf_1)) && (selection < (int'(res_cf_1) + `NUM_CONTROL_FLOW_STATIONS));
end

// Place outputs on common data bus
assign data_bus_out.dest = finish ? data[finish_index].dest : `REORDER_ID_INVALID;
assign data_bus_out.value = finish ? outputs[finish_index] : 16'd0;
assign data_bus_out.update_pc_value = new_pcs[finish_index];
assign data_bus_out.ready = 1;
// Only update if we predict incorrectly
// TODO: can add an optimization by not choosing a new pc if it
// was going to be chosen anyway (ie the jmp target is just the next instruction)
`ifdef BRANCH_PREDICTION_ENABLED
assign data_bus_out.update_pc = finish ? (pc_taken[finish_index] != predictions[finish_index]) : 1'b0;
`else
// Assume we always don't take the branch
assign data_bus_out.update_pc = finish ? pc_taken[finish_index] : 1'b0;
`endif

// Output information about the finished instruction to fetch
assign cf_update = finish;
assign cf_pc = data[finish_index].pc;
assign cf_target = targets[finish_index];
assign cf_op = data[finish_index].op;
assign cf_taken = pc_taken[finish_index];

// Connect the control flow inputs to the reservation station data
genvar i;
generate
for (i = 0; i < size; i++) begin : gen_block_id
	control_flow cfz(
		.clk(clk),
		
		.op(data[i].op),
		.pc(data[i].pc),
		.vj(data[i].vj),
		.vk(data[i].vk),
		.load(ready[i]),
		.data_out(outputs[i]),
		.new_pc(new_pcs[i]),
		.target(targets[i]),
		.ready(complete[i]),
		.taken(pc_taken[i])
	);
end
endgenerate

endmodule : control_flow_rs

module control_flow(
	input clk,
	input logic[3:0] op,
	input lc3b_word pc,
	input lc3b_word vj,
	input lc3b_word vk,
	
	input load,
	
	output lc3b_word data_out,
	output lc3b_word new_pc,
	output lc3b_word target,
	output logic ready,
	output logic taken
);

always_comb begin
	// Default values
	ready = 1'b0;
	taken = 1'b0;
	new_pc = 'd0;
	target = 'd0;
	data_out = 'd0;
	
	case (op)
		`CF_JUMP: begin
			ready = load;
			taken = 1'b1;
			new_pc = vj;
			target = vj;
		end
		`CF_JSR: begin
			ready = load;
			taken = 1'b1;
			data_out = pc + 16'd2;
			new_pc = pc + 16'd2 + vj;
			target = pc + 16'd2 + vj;
		end
		`CF_JSRR: begin
			ready = load;
			taken = 1'b1;
			data_out = pc + 16'd2;
			new_pc = vj;
			target = vj;
		end
		`CF_BRANCH: begin
			ready = load;
			// Condition codes are in vk[11:9], offset is in vk[8:0]
			// Value that calculates the CC are in vj
			target = pc + 16'd2 + 16'($signed({ vk[8:0], 1'b0 }));
			taken = (vk[11] && vj[15])	||							// n
					(vk[10] && (vj == 16'd0)) ||					// z
					(vk[9] && !vj[15] && (vj != 16'd0));		// p
			new_pc = taken ? target : pc + 16'd2;
		end
		default: begin
		end
	endcase
end

endmodule : control_flow
