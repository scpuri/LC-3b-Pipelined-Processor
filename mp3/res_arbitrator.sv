import lc3b_types::*;

`include "macros.sv"

// Choose which entry to select if multiple are complete 
module res_arbitrator #(parameter size=`NUM_STATIONS)(
	input clk,
	
	input logic resp,
	
	input logic[size-1:0] complete,
	output logic[$bits(size)-1:0] selection,
	output logic load
);

logic prev_resp;

initial
begin
    prev_resp = 0;
end

// TODO: make this more complex (such as tracking number of dependencies)
// For now, choose the first one
always_comb
begin
	load = 1'b0;
	selection = '0;
	
	if(!prev_resp) // wastes bus access on ldi
	begin
		for (int z = 0; z < size; z++) begin
			if (complete[z]) begin
				selection = z;
				load = 1'b1;
				break;
			end
		end
	end
end

// delay resp by a cycle to allow lsq to ready data for cdb
always_ff @ (posedge clk)
begin
    if(resp)
        prev_resp <= 1;
    else
        prev_resp <= 0;
end

endmodule : res_arbitrator
