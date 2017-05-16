import lc3b_types::*;
`include "macros.sv"

module loadstore_queue (
	input clk,
	
	lc3b_cdb data_bus,
	lc3b_cdb data_bus_out,
	
	/* New load entry */
	input logic new_load_entry,
	input lc3b_rob_id load_pos,
	input lc3b_lsq_op load_type,
	input lc3b_word load_pc,
	// address calculated in agu, snooped off cdb
	
	/* New store entry */
	input logic new_store_entry,
	input lc3b_rob_id store_pos,
	input lc3b_lsq_op store_type,
	input logic store_val_ready,
	input lc3b_regfile_entry store_val,

	/* Mem signals */
	output logic read,
	output logic write,
	output logic [1:0] wmask,
	output logic [15:0] address,
	output logic [15:0] wdata,
	input logic resp,
	input logic [15:0] rdata,
	
	input lc3b_rob_id rob_head,
	input logic flush,
	output logic full
);

// Loads and stores in separate logical queues
// In same module to facilitate forwarding

/* Load queue data */
lc3b_lq_entry loadq[`LQ_SIZE];
lc3b_lq_id lq_tail;
logic lq_full;
lc3b_lq_id lq_oldest_ready;
logic lq_entry_ready;
lc3b_lq_id cur_load;

/* Store queue data */
lc3b_sq_entry storeq[`SQ_SIZE];
lc3b_sq_id sq_tail;
logic sq_full;
logic sq_entry_ready;
logic unknown_st_addr;

logic waiting;

initial
begin
	for(int i = 0; i < `LQ_SIZE; i++)
		loadq[i] = '0;
	for(int i = 0; i < `SQ_SIZE; i++)
		storeq[i] = '0;
	read = 0;
	write = 0;
	cur_load = '0;
end

always_ff @ (posedge clk)
begin
	if(flush)
	begin
		for(int i = 0; i < `LQ_SIZE; i++)
			loadq[i] = '0;
		for(int i = 0; i < `SQ_SIZE; i++)
			storeq[i] = '0;
		read = 0;
		write = 0; // MAKE SURE CACHE CAN DEAL WITH WRITE GOING LOW MID-WRITE
		cur_load = 0;
	end
	
	/* Receive load from memory */
	if(resp && read)
	begin
		read = 0;
		if(loadq[cur_load].op == lq_ldi)
		begin
			// put ldr back into this slot
			loadq[cur_load].op = lq_ldr;
			loadq[cur_load].address = rdata;
		end
		else if (loadq[cur_load].op == lq_trap)
		begin
			data_bus_out.dest = loadq[cur_load].rob_id;
			data_bus_out.update_pc_value = rdata;
			data_bus_out.update_pc = 1'b1;
			data_bus_out.ready = 1'b1;
			data_bus_out.value = loadq[cur_load].pc + 16'd2;
			
			loadq[cur_load].valid = 1'b0;
		end
		else
		begin
			data_bus_out.dest = loadq[cur_load].rob_id;
			data_bus_out.update_pc_value = 'd0;
			data_bus_out.update_pc = 1'b0;
			data_bus_out.ready = 1;
			if(loadq[cur_load].op == lq_ldr)
				data_bus_out.value = rdata;
			else if(loadq[cur_load].address[0] == 0)
				data_bus_out.value = {8'b0, rdata[7:0]};
			else
				data_bus_out.value = {8'b0, rdata[15:8]};
			
			loadq[cur_load].valid = 0;
		end
	end
	else if(resp && write)
	begin
		write = 0;
		storeq[0].valid = 0;
		// let rob know that store has committed
		data_bus_out.dest = storeq[0].rob_id;
		data_bus_out.update_pc_value = 'd0;
		data_bus_out.update_pc = 1'b0;
		data_bus_out.ready = 1;
		data_bus_out.value = storeq[0].value;
	end
	else
		data_bus_out.ready = 0;
	
	/* Collapse load queue if openings */
	for(int i = 1; i < `LQ_SIZE; i++)
	begin
		if(!loadq[i-1].valid)
		begin
			loadq[i-1] = loadq[i];
			loadq[i].valid = 0;
		end
	end
	
	/* Collapse store queue if openings */
	for(int i = 1; i < `SQ_SIZE; i++)
	begin
		if(!storeq[i-1].valid)
		begin
			storeq[i-1] = storeq[i];
			storeq[i].valid = 0;
		end
	end
	
	/* Receive calculated load address from cdb */
	for(int i = 0; i < `LQ_SIZE; i++)
	begin
		if((data_bus.dest == loadq[i].rob_id) && !(loadq[i].addr_ready))
		begin
			loadq[i].address = data_bus.value;
			loadq[i].addr_ready = 1'b1;
		end
	end
	
	// Use data_bus.ready to distinguish b/w agu and alu output 
	
	/* Receive calculated store address from cdb */
	for(int i = 0; i < `SQ_SIZE; i++)
	begin
		if((data_bus.dest == storeq[i].rob_id) && !(data_bus.ready) && !(storeq[i].addr_ready))
		begin
			storeq[i].address = data_bus.value;
			storeq[i].addr_ready = 1'b1;
		end
	end
	
	/* New load queue entry */
	// TODO: make sure lq_tail updating correctly and in time with collapse
	if(new_load_entry && !lq_full)
	begin
		loadq[lq_tail].valid = 1'b1;
		loadq[lq_tail].rob_id = load_pos;
		loadq[lq_tail].op = load_type;
		loadq[lq_tail].addr_ready = 1'b0;
		loadq[lq_tail].address = `INVALID_ADDRESS;
		loadq[lq_tail].pc = load_pc;
	end
	
	/* New store queue entry */
	if(new_store_entry && !sq_full)
	begin
		storeq[sq_tail].valid = 1'b1;
		storeq[sq_tail].rob_id = store_pos;
		storeq[sq_tail].op = store_type;
		storeq[sq_tail].addr_ready = 1'b0;
		if(store_val.rob_id == `REORDER_ID_INVALID)
		begin
			storeq[sq_tail].value = store_val.value;
			storeq[sq_tail].val_ready = 1'b1;
		end
		else
		begin
			storeq[sq_tail].val_rob_id = store_val.rob_id;
			storeq[sq_tail].val_ready = 1'b0;
		end
	end

	/* Receive calculated store value from cdb */
	for(int i = 0; i < `SQ_SIZE; i++)
	begin
		if((data_bus.dest == storeq[i].val_rob_id) && (data_bus.ready) && !(storeq[i].val_ready))
		begin
			storeq[i].value = data_bus.value;
			storeq[i].val_ready = 1'b1;
		end
	end

	/* Send ready store to memory */
	if(sq_entry_ready && !waiting)
	begin
		write = 1;
		wdata = storeq[0].value;
		case(storeq[0].op)
			sq_str: address = {storeq[0].address[15:1], 1'b0};
			sq_sti: address = {storeq[0].address[15:1], 1'b0};
			sq_stb: address = storeq[0].address;// TODO: wmask
		endcase
	end

	/* Send ready load to memory */
	if(lq_entry_ready && !waiting && !unknown_st_addr)
	begin
		read = 1;
		case(loadq[lq_oldest_ready].op)
			lq_ldr: address = {loadq[lq_oldest_ready].address[15:1], 1'b0};
			lq_ldi: address = {loadq[lq_oldest_ready].address[15:1], 1'b0};
			lq_ldb: address = loadq[lq_oldest_ready].address;
			lq_trap: address = loadq[lq_oldest_ready].address << 1;  // raw trapvect8 passed through agu
		endcase
		cur_load = lq_oldest_ready;
	end

end

always_comb
begin
	/* Find oldest load entry ready for memory */
	lq_entry_ready = 0;
	lq_oldest_ready = '0;
	
	for(int i = 0; i < `LQ_SIZE; i++)
	begin
		if(loadq[i].valid && loadq[i].addr_ready)
		begin
			lq_entry_ready = 1;
			lq_oldest_ready = 4'(i);
			break;
		end
	end
	
	sq_entry_ready = (storeq[0].valid && 
							storeq[0].addr_ready && 
							storeq[0].val_ready && 
							storeq[0].rob_id == rob_head);
	
	/* Find loadq tail */
	lq_tail = 4'(`LQ_SIZE - 1); // shouldn't need this. if queue full, no new entries can occur anyway.
	
	for(int i = 0; i < `LQ_SIZE; i++)
	begin
		if(!loadq[i].valid)
		begin
			lq_tail = 4'(i);
			break;
		end
		else
			lq_tail = 4'(`LQ_SIZE - 1);
	end
	
	/* Find storeq tail */
	sq_tail = 4'(`SQ_SIZE - 1); // shouldn't need this. if queue full, no new entries can occur anyway.
	
	for(int i = 0; i < `SQ_SIZE; i++)
	begin
		if(!storeq[i].valid)
		begin
			sq_tail = 4'(i);
			break;
		end
		else
			sq_tail = 4'(`LQ_SIZE - 1);
	end
	
	/* Check to see if any uncalculated addresses */
	unknown_st_addr = 0;
	for(int i = 0; i < `SQ_SIZE; i++)
	begin
		if(storeq[i].valid && !storeq[i].addr_ready)
		begin
			unknown_st_addr = 1;
			break;
		end
	end	
	
	lq_full = (lq_tail == `LQ_SIZE - 1) ? '1 : '0;
	sq_full = (sq_tail == `SQ_SIZE - 1) ? '1 : '0;
	full = lq_full || sq_full;
	waiting = read || write;
	wmask = 2'b11;
end

endmodule : loadstore_queue
