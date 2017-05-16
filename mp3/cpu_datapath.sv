import lc3b_types::*;
`include "macros.sv"

module cpu_datapath(
	input clk,
	
	/* Memory signals */
	//Used in fetch
   input mem_resp_a,
   input lc3b_word mem_rdata_a,
   output mem_read_a,
   output mem_write_a,
   output lc3b_mem_wmask mem_byte_enable_a,
   output lc3b_word mem_address_a,
   output lc3b_word mem_wdata_a,

	input mem_resp_b,
   input lc3b_word mem_rdata_b,
   output mem_read_b,
   output mem_write_b,
   output lc3b_mem_wmask mem_byte_enable_b,
   output lc3b_word mem_address_b,
   output lc3b_word mem_wdata_b
);

// Common data bus
lc3b_cdb common_data_bus();

// Flush everything!
logic flush;

// Fetch intermediates
lc3b_word fetch_pc_out, fetch_instruction_out;
logic fetch_ready, fetch_stalled;
logic sel_update_pc;
lc3b_word sel_update_pc_value;
logic cf_update, cf_taken;
logic [3:0] cf_op;
lc3b_word cf_pc, cf_target;
logic fetch_branch_prediction;

// Decode intermediates
logic iq_full, load_reorder;
lc3b_iqueue_entry iq_out;
lc3b_rs_id load_res_id;

// Reservation station intermediates
logic ld_reservations[`NUM_STATIONS-1:0];
logic reservations_available[`NUM_STATIONS-1:0];
logic[`NUM_STATIONS-1:0] reservations_complete;
logic[$bits(`NUM_STATIONS)-1:0] reservation_selection;
logic finish_reservation;
logic[3:0] reservation_op;
lc3b_word reservation_vj;
lc3b_word reservation_vk;
lc3b_rob_id reservation_qj;
lc3b_rob_id reservation_qk;
lc3b_word reservation_pc;
logic reservation_prediction;

// Loadstore queue intermediates
logic lsq_full;
logic new_load_entry;
logic new_store_entry;
logic store_val_ready;
lc3b_regfile_entry store_val;

// Reorder buffer intermediates
lc3b_rob_id rob_current_index, rob_head;
lc3b_ext_reg rob_commit_reg;
lc3b_word rob_commit_value;
logic rob_full, rob_commit;
logic load_reg_rob;
lc3b_rob_id reg_rob;
lc3b_ext_reg rob_dest;
lc3b_ext_reg regfile_dest;

// Regfile intermediates
lc3b_regfile_entry reg_data[7:0];

// Execute intermediates
lc3b_cdb alu_rs_cdb(), cf_rs_cdb(), agu_rs_cdb(), lsq_cdb();
logic alu_rs_finish, cf_rs_finish, agu_rs_finish;

// Fetch stage
cpu_fetch fetch(
	.*,
	.stalled(fetch_stalled || rob_full || lsq_full), // TODO: need to stall on rob_full or lsq_full?
	.pc_out(fetch_pc_out),
	.instruction_out(fetch_instruction_out),
	.prediction_out(fetch_branch_prediction),
	.ready(fetch_ready)
);

// Decode stage
cpu_decode decode(
	.clk(clk),
	.pc(fetch_pc_out),
	.instruction(fetch_instruction_out),
	.branch_prediction(fetch_branch_prediction),
	.input_ready(fetch_ready),
	.reservations_available(reservations_available),
	.ld_reservations(ld_reservations),
	.load_res(load_res_id),
	.load_reorder(load_reorder),
	.data_out(iq_out),
	.flush(flush),
	.stall_output(rob_full || lsq_full),
	.stall_input(fetch_stalled),
	.lq(new_load_entry),
	.sq(new_store_entry),
	.store_val(store_val),
	
	.regfile_data(reg_data),
	.op_out(reservation_op),
	.qj_out(reservation_qj),
	.qk_out(reservation_qk),
	.vj_out(reservation_vj), 
	.vk_out(reservation_vk),
	.dest_reg_out(regfile_dest),
	.pc_out(reservation_pc),
	.prediction_out(reservation_prediction)
);

// Execute stage (all the reservation stations, arbitrator)
alu_rs alu_stations(
	.clk(clk),
	.ld_reservations(ld_reservations[int'(res_alu_1) +: `NUM_ALU_STATIONS]),
	.reservations_available(reservations_available[int'(res_alu_1) +: `NUM_ALU_STATIONS]),
	.complete(reservations_complete[int'(res_alu_1) +: `NUM_ALU_STATIONS]),
	.selection(reservation_selection),
	.sel_load(finish_reservation),
	.rob_commit_value(rob_commit_value),
	.rob_commit(rob_commit),
	.rob_commit_pos(rob_head),
	.op_in(reservation_op),
	.qj_in(reservation_qj),
	.qk_in(reservation_qk),
	.vj_in(reservation_vj),
	.vk_in(reservation_vk),
	.dest_in(rob_current_index),
	.pc_in(reservation_pc),
	.data_bus(common_data_bus),
	.data_bus_out(alu_rs_cdb),
	.finish(alu_rs_finish),
	.flush(flush)
);

agu_rs agu_stations(
	.clk(clk),
	.ld_reservations(ld_reservations[int'(res_agu_1) +: `NUM_AGU_STATIONS]),
	.reservations_available(reservations_available[int'(res_agu_1) +: `NUM_AGU_STATIONS]),
	.complete(reservations_complete[int'(res_agu_1) +: `NUM_AGU_STATIONS]),
	.selection(reservation_selection),
	.sel_load(finish_reservation),
	.rob_commit_value(rob_commit_value),
	.rob_commit(rob_commit),
	.rob_commit_pos(rob_head),
	.op_in(reservation_op),
	.qj_in(reservation_qj),
	.qk_in(reservation_qk),
	.vj_in(reservation_vj),
	.vk_in(reservation_vk),
	.dest_in(rob_current_index),
	.pc_in(reservation_pc),
	.data_bus(common_data_bus),
	.data_bus_out(agu_rs_cdb),
	.finish(agu_rs_finish),
	.flush(flush)
);

control_flow_rs cf_stations(
	.clk(clk),
	.ld_reservations(ld_reservations[int'(res_cf_1) +: `NUM_CONTROL_FLOW_STATIONS]),
	.reservations_available(reservations_available[int'(res_cf_1) +: `NUM_CONTROL_FLOW_STATIONS]),
	.complete(reservations_complete[int'(res_cf_1) +: `NUM_CONTROL_FLOW_STATIONS]),
	.selection(reservation_selection),
	.sel_load(finish_reservation),
	.rob_commit_value(rob_commit_value),
	.rob_commit(rob_commit),
	.rob_commit_pos(rob_head),
	.op_in(reservation_op),
	.qj_in(reservation_qj),
	.qk_in(reservation_qk),
	.vj_in(reservation_vj),
	.vk_in(reservation_vk),
	.dest_in(rob_current_index),
	.pc_in(reservation_pc),
	.prediction_in(reservation_prediction),
	.data_bus(common_data_bus),
	.data_bus_out(cf_rs_cdb),
	.finish(cf_rs_finish),
	
	// Outputs to fetch
	.cf_update(cf_update),
	.cf_pc(cf_pc),
	.cf_target(cf_target),
	.cf_op(cf_op),
	.cf_taken(cf_taken),
	
	.flush(flush)
);

// Common data bus (prioritize agu then alu then cf even though its
// impossible for both to drive at once due to the arbitrator)
always_comb
begin
	if(lsq_cdb.ready)
	begin
		common_data_bus.dest = lsq_cdb.dest;
		common_data_bus.value = lsq_cdb.value;
		common_data_bus.update_pc_value = lsq_cdb.update_pc_value;
		common_data_bus.update_pc = lsq_cdb.update_pc;
		common_data_bus.ready = lsq_cdb.ready;
	end
	else if(agu_rs_finish)
	begin
		common_data_bus.dest = agu_rs_cdb.dest;
		common_data_bus.value = agu_rs_cdb.value;
		common_data_bus.update_pc_value = agu_rs_cdb.update_pc_value;
		common_data_bus.update_pc = agu_rs_cdb.update_pc;
		common_data_bus.ready = agu_rs_cdb.ready;
	end
	else if(alu_rs_finish)
	begin
		common_data_bus.dest = alu_rs_cdb.dest;
		common_data_bus.value = alu_rs_cdb.value;
		common_data_bus.update_pc_value = alu_rs_cdb.update_pc_value;
		common_data_bus.update_pc = alu_rs_cdb.update_pc;
		common_data_bus.ready = alu_rs_cdb.ready;
	end
	else if(cf_rs_finish)
	begin
		common_data_bus.dest = cf_rs_cdb.dest;
		common_data_bus.value = cf_rs_cdb.value;
		common_data_bus.update_pc_value = cf_rs_cdb.update_pc_value;
		common_data_bus.update_pc = cf_rs_cdb.update_pc;
		common_data_bus.ready = cf_rs_cdb.ready;
	end
	else
	begin
		common_data_bus.dest = 'Z;
		common_data_bus.value = 'Z;
		common_data_bus.update_pc_value = 'Z;
		common_data_bus.update_pc = '0;
		common_data_bus.ready = '0;
	end
end

/* 
assign common_data_bus.dest = alu_rs_finish ? alu_rs_cdb.dest :
 (cf_rs_finish ? cf_rs_cdb.dest : 'Z);
assign common_data_bus.value = alu_rs_finish ? alu_rs_cdb.value :
 (cf_rs_finish ? cf_rs_cdb.value : 'Z);
assign common_data_bus.update_pc_value = alu_rs_finish ? alu_rs_cdb.update_pc_value :
 (cf_rs_finish ? cf_rs_cdb.update_pc_value : 'Z);
assign common_data_bus.update_pc = alu_rs_finish ? alu_rs_cdb.update_pc :
 (cf_rs_finish ? cf_rs_cdb.update_pc : '0);
*/

// Chooses which reservation station gets to put its values on the bus if there are conflicts
res_arbitrator arb(
	.clk(clk),
	.complete(reservations_complete),
	.selection(reservation_selection),
	.load(finish_reservation),
	.resp(mem_resp_b)
);

// Loadstore queue
loadstore_queue lsq(
	.clk(clk),
	.data_bus(common_data_bus),
	.data_bus_out(lsq_cdb),
	.new_load_entry(new_load_entry),
	.load_pos(rob_current_index),
	.load_type(lc3b_lsq_op'(reservation_op[2:0])),
	.load_pc(reservation_pc),
	.new_store_entry(new_store_entry),
	.store_pos(rob_current_index),
	.store_type(lc3b_lsq_op'(reservation_op[2:0])),
	.store_val_ready(store_val_ready),
	.store_val(store_val),
	.read(mem_read_b),
	.write(mem_write_b),
	.wmask(mem_byte_enable_b),
	.address(mem_address_b),
	.wdata(mem_wdata_b),
	.resp(mem_resp_b),
	.rdata(mem_rdata_b),
	.rob_head(rob_head),
	.flush(flush),
	.full(lsq_full)
);

// Commit stage (reorder buffer and regfile)
reorder_buffer rb(
	.clk(clk),
	.data_bus(common_data_bus),
	.rs_in(load_res_id),
	.reg_in(regfile_dest),
	.load(load_reorder),
	.current_index(rob_current_index),
	.full(rob_full),
	.commit_reg(rob_commit_reg),
	.commit_value(rob_commit_value),
	.commit(rob_commit),
	.head(rob_head),
	.rob_dest(rob_dest),
	.reg_rob(reg_rob),
	.load_reg_rob(load_reg_rob),
	
	.sel_update_pc(sel_update_pc),
	.sel_update_pc_value(sel_update_pc_value),
	
	.flush(flush)
);

// Registers
regfile regs(
	.clk(clk),
	.flush(flush),
	.load_value(rob_commit),
	.load_rob(load_reg_rob),
	.value_in(rob_commit_value),
	.rob_in(reg_rob),
	.dest_value(rob_commit_reg),
	.dest_rob(rob_dest),
	.data(reg_data)
);

endmodule : cpu_datapath