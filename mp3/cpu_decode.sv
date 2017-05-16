import lc3b_types::*;
`include "macros.sv"

// Decodes the instruction and places it in the instruction queue.
// From there, it places the instruction from the queue into the corresponding reservation station
module cpu_decode(
	input clk,
		
	input flush,
	input stall_output,
	input lc3b_word pc,
	input lc3b_word instruction,
	input logic branch_prediction,
	input input_ready,
	input lc3b_regfile_entry regfile_data[7:0],
	
	input logic reservations_available[`NUM_STATIONS-1:0],
	output logic ld_reservations[`NUM_STATIONS-1:0],
	output lc3b_rs_id load_res,
	output logic load_reorder,
	output lc3b_iqueue_entry data_out,
	output logic stall_input,
	output logic lq,
	output logic sq,
	output lc3b_regfile_entry store_val,

	output logic[3:0] op_out,
	output lc3b_rob_id qj_out, qk_out,
	output lc3b_word vj_out, vk_out,
	output lc3b_ext_reg dest_reg_out,
	output lc3b_word pc_out,
	output logic prediction_out
);

logic iq_full, stall_decode;
lc3b_iqueue_entry entry;
logic iqueue_data_valid;
logic gen_cc;

assign entry.pc = pc;
assign entry.instruction = instruction;
assign entry.prediction = branch_prediction;

// Assign whichever reservation station to be loaded (we can only load if we aren't currently flushing)
always_comb
begin
	load_reorder = load_res != '0 && iqueue_data_valid;
	for (int z = 1; z < `NUM_STATIONS; z++)
		ld_reservations[z] = (int'(load_res) == z) && iqueue_data_valid;
end

// Register that holds the last CC destination for branches
lc3b_ext_reg last_cc_reg;
initial begin
	last_cc_reg = `REGISTER_PC;	// No register
end

always_ff @(posedge clk) begin
	if (gen_cc && load_reorder) begin
		last_cc_reg = dest_reg_out;
	end
end

iqueue instruction_queue(
	.clk,
	.flush(flush),
	.stalled(stall_output || stall_decode),
	.data_in(entry),
	.load(input_ready),
	.data_out(data_out),
	.data_valid(iqueue_data_valid),
	.full(iq_full)
);

decoder d0(
	.data_in(data_out),
	.last_cc_reg(last_cc_reg),
	.data(regfile_data),
	.reservations_available(reservations_available),
	.op_out(op_out),
	.qj_out(qj_out),
	.qk_out(qk_out),
	.vj_out(vj_out), 
	.vk_out(vk_out),
	.dest_reg_out(dest_reg_out),
	.pc_out(pc_out),
	.prediction_out(prediction_out),
	.res_id_out(load_res),
	.store_val(store_val),
	.gen_cc(gen_cc),
	.lq(lq),
	.sq(sq),
	.stall_decode(stall_decode)
);

assign stall_input = iq_full;

endmodule : cpu_decode