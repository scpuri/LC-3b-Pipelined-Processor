import lc3b_types::*;
`include "macros.sv"

module iqueue(
	input clk,
	
	input flush,
	input stalled,
	input lc3b_iqueue_entry data_in,
	input load,
	
	output lc3b_iqueue_entry data_out,
	output logic data_valid,
	output logic full
);

logic [`BITS_OF_INSTRUCTION_SLOTS-1:0] head, tail;
logic [`BITS_OF_INSTRUCTION_SLOTS:0] space_used;

logic [$bits(lc3b_iqueue_entry)-1:0] data [`NUMBER_INSTRUCTION_SLOTS-1:0];
logic [`NUMBER_INSTRUCTION_SLOTS-1:0] valid;

// Make sure these default to the correct values
initial
begin
	head = '0;
	tail = '0;
	valid = '0;
	space_used = '0;
end

assign full = (space_used == (`BITS_OF_INSTRUCTION_SLOTS+1)'(`NUMBER_INSTRUCTION_SLOTS));

// TODO: add more complex logic to select which entry we want to check is available
// For now, just issue in order
assign data_out = data[head];
assign data_valid = valid[head];

always_ff @(posedge clk)
begin
	if (!stalled && valid[head]) begin
		// Pop that entry off the queue
		valid[head] = 1'b0;
		head = head + 1'b1;
		space_used = space_used - 1'b1;
	end
		
	// Load things
	if (load && !full)
	begin
		data[tail] = data_in;
		valid[tail] = 1'b1;
		tail = tail + 1'b1;
		space_used = space_used + 1'b1;
	end
	
	// Flush everything
	if (flush) begin
		head = '0;
		tail = '0;
		valid = '0;
		space_used = '0;
	end
end

endmodule : iqueue