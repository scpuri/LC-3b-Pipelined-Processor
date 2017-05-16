import lc3b_types::*;
`include "macros.sv"

module alu_rs #(parameter size=`NUM_ALU_STATIONS)(
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
	
	lc3b_cdb data_bus,
	lc3b_cdb data_bus_out,
	output logic finish,
	
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
lc3b_rs_entry data[size];
lc3b_rs_id finish_index;
logic load_res;

assign index = lc3b_rs_id'(find_loaded_rs(ld_reservations) - 1);
assign load_res = find_loaded_rs(ld_reservations) != int'(res_invalid);

reservation_station #(`NUM_ALU_STATIONS) alu_station (
	.*,
	.load(load_res)
);

// Since each alu instruction takes 1 cycle, just say they are complete if they are ready
assign complete = ready;

// Temp: make each alu instruction take 3 cycles
/*logic[2:0] state[size-1:0];
initial begin
	for (int z = 0; z < size; z++)
		state[z] = '0;
end
always_ff @(posedge clk)
begin
	for (int z = 0; z < size; z++) begin
		case (state[z])
			0: state[z] = ready[z] ? 1 : 0;
			1: state[z] = 2;
			2: state[z] = 3;
			3: begin complete[z] = 1'b1; state[z] = 4; end
			4: begin state[z] = 0; complete[z] = 1'b0; end
			default: state[z] = 0;
		endcase
		
		if (flush) begin
			state[z] = 0;
		end
	end
end*/

// Mark selected the station as finished
always_comb
begin
	finish_index = lc3b_rs_id'(selection - int'(res_alu_1));
	finish = sel_load && (selection >= int'(res_alu_1)) && (selection < (int'(res_alu_1) + `NUM_ALU_STATIONS));
end

// Place outputs on common data bus
assign data_bus_out.dest = finish ? data[finish_index].dest : `REORDER_ID_INVALID;
assign data_bus_out.value = finish ? outputs[finish_index] : 16'd0;
assign data_bus_out.update_pc_value = 'd0;
assign data_bus_out.update_pc = 1'b0;
assign data_bus_out.ready = 1;

// Connect the alu inputs to the reservation station data
genvar i;
generate
for (i = 0; i < size; i++) begin : gen_block_id
	alu aluz(
		.a(data[i].vj),
		.b(data[i].vk),
		.op(lc3b_aluop'(data[i].op)),
		.f(outputs[i])
	);
end
endgenerate

endmodule : alu_rs