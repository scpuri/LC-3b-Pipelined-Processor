import lc3b_types::*;
`include "macros.sv"

typedef struct packed {
	lc3b_rs_id rs_id;				// ID of resrvation station that sets this value
	lc3b_ext_reg register;		// Register ID of destination
	lc3b_word value;				// Value of register
	lc3b_word update_pc_value;			// New PC value
	logic update_pc;				// Should we update the PC?
	logic valid;					// Data ready
	logic ready;
} lc3b_rob_entry;

module reorder_buffer
(
	input clk,
	
	// Common data bus
	lc3b_cdb data_bus,
	
	input lc3b_rs_id rs_in,
	input lc3b_ext_reg reg_in,
	input load,
	
	output lc3b_rob_id current_index,		// The index the next load will go to
	output logic full,
	
	output lc3b_ext_reg commit_reg,
	output lc3b_word commit_value,
	output logic commit,
	output lc3b_rob_id head,
	
	output lc3b_ext_reg rob_dest,
	output lc3b_rob_id reg_rob,
	output logic load_reg_rob,
	
	// Select new PC
	output logic sel_update_pc,
	output lc3b_word sel_update_pc_value,
	// Flush everything...
	output logic flush
);

// Head and tail pointers
lc3b_rob_id tail;
logic [$bits(lc3b_rob_id):0] space_used;

// Data array
lc3b_rob_entry data[`REORDER_BUFFER_SIZE];

// Make sure we get the correct default values
initial
begin
	head = 0;
	tail = 0;
	space_used = 0;
	for (int z = 0; z < `REORDER_BUFFER_SIZE; z++) begin
		data[z] = '0;
	end
end

assign current_index = tail[$bits(lc3b_rob_id)-1:0];

// Update which ROB entry we can find the most recent value of the register to load
always_comb
begin
	load_reg_rob = load && !full;
	rob_dest = reg_in;
	reg_rob = lc3b_rob_id'(tail[$bits(lc3b_rob_id)-1:0]);
end

// Add a new element in the queue when needed
always_ff @(posedge clk)
begin
	if (load && !full) begin
		data[tail].rs_id = rs_in;
		data[tail].register = reg_in;
		data[tail].value = '0;
		data[tail].update_pc_value = 'd0;
		data[tail].update_pc = 1'b0;
		data[tail].valid = 1'b0;
		data[tail].ready = 1'b0;
		
		tail = (tail == (`REORDER_BUFFER_SIZE - 1)) ? '0 : tail + 1'b1;
		space_used = space_used + 1'b1;
	end
	
	// Set the contents of the finished instruction from the common data bus
	if (data_bus.dest != `REORDER_ID_INVALID) begin
		data[data_bus.dest].value = data_bus.value;
		data[data_bus.dest].update_pc_value = data_bus.update_pc_value;
		data[data_bus.dest].update_pc = data_bus.update_pc;
		data[data_bus.dest].valid = 1'b1;
		data[data_bus.dest].ready = data_bus.ready;
	end
	
	// Commit (advance the head pointer)
	if (commit) begin
		data[head].valid = 1'b0;
		head = (head == (`REORDER_BUFFER_SIZE - 1)) ? '0 : head + 1'b1;
		space_used = space_used - 1'b1;
	end
	
	// Flush the reorder buffer
	if (flush) begin
		head = 0;
		tail = 0;
		space_used = 0;
		
		for (int z = 0; z < `REORDER_BUFFER_SIZE; z++) begin
			data[z] = '0;
		end
	end
end


// Determine if we need to commit and the values that we want to commit
always_comb
begin
	commit = (data[head].valid && data[head].ready);
	commit_value = data[head].value;
	commit_reg = data[head].register;
	
	// Flush if we need to
	flush = (data[head].valid && data[head].update_pc);
	sel_update_pc = flush;
	sel_update_pc_value = data[head].update_pc_value;
end

// Determine if we are full
always_comb
begin
	full = (space_used == `REORDER_BUFFER_SIZE);
end

endmodule : reorder_buffer