import lc3b_types::*;
`include "macros.sv"

module reservation_station #(parameter size=4)
(
	input clk,
	
	input load,
	input lc3b_rs_id index,
	
	input finish,
	input lc3b_rs_id finish_index,
	
	input logic[3:0] op_in,
	input lc3b_word vj_in, vk_in,
	input lc3b_rob_id qj_in, qk_in,
	input lc3b_rob_id dest_in,
	input lc3b_word pc_in,
	
	input lc3b_word rob_commit_value,
	input rob_commit,
	input lc3b_rob_id rob_commit_pos,
	
	lc3b_cdb data_bus,
	
	input flush,
	
	output lc3b_rs_entry data[size],
	output logic[size-1:0] ready,
	output logic reservations_available[size-1:0]
);

// Initial values
initial begin
	for (int z = 0; z < size; z++) begin
		data[z] = '0;
	end
end

// Load an entry and check inputs to mark as ready
always_ff @(posedge clk)
begin
	if (load) begin
		data[index].op = op_in;
		data[index].qj = qj_in;
		data[index].qk = qk_in;
		data[index].vj = vj_in;
		data[index].vk = vk_in;
		data[index].rj = (qj_in == `REORDER_ID_INVALID);	// (enables instructions of 1 cycles)
		data[index].rk = (qk_in == `REORDER_ID_INVALID);
		data[index].dest = dest_in;
		data[index].pc = pc_in;
		data[index].busy = 1'b1;
	end
	if (finish) begin
		data[finish_index].busy = 1'b0;
		data[finish_index].rj = 1'b0;
		data[finish_index].rk = 1'b0;
		data[finish_index].qj = `REORDER_ID_INVALID;
		data[finish_index].qk = `REORDER_ID_INVALID;
	end
	
	for (int z = 0; z < size; z++) begin
		// Get data from data bus if its on it (enables instructions of 3 or more cycles)
		if (data_bus.dest == data[z].qj && data[z].qj != `REORDER_ID_INVALID && data[z].busy && data_bus.ready) begin
			data[z].vj = data_bus.value;
			data[z].rj = 1'b1;
		end
		if (data_bus.dest == data[z].qk && data[z].qk != `REORDER_ID_INVALID && data[z].busy && data_bus.ready) begin
			data[z].vk = data_bus.value;
			data[z].rk = 1'b1;
		end
		
		// Get data from the currently committing rob entry if its the right one (enable instructions of 2 cycles)
		if (data[z].qj == rob_commit_pos && rob_commit_pos != `REORDER_ID_INVALID && rob_commit && data[z].busy) begin
			data[z].vj = rob_commit_value;
			data[z].rj = 1'b1;
		end
		if (data[z].qk == rob_commit_pos && rob_commit_pos != `REORDER_ID_INVALID && rob_commit && data[z].busy) begin
			data[z].vk = rob_commit_value;
			data[z].rk = 1'b1;
		end
	end
	
	// Flush everything
	if (flush) begin
		for (int z = 0; z < size; z++) begin
			data[z] = '0;
		end
	end
end

// Let the output know when a slot is ready to execute
always_comb
begin
	for (int z = 0; z < size; z++)
		ready[z] <= (data[z].rj && data[z].rk);
end

// Determine which reservation stations are available
always_comb
begin
	for (int z = 0; z < size; z++)
		reservations_available[z] <= !data[z].busy;
end

endmodule : reservation_station