import lc3b_types::*;

`include "macros.sv"

module regfile
(
    input clk,
	 input flush,
    input load_value,
	 input load_rob,
    input lc3b_word value_in,
	 input lc3b_rob_id rob_in,
    input lc3b_ext_reg dest_value,
	 input lc3b_ext_reg dest_rob,
	 output lc3b_regfile_entry data[7:0] /* synthesis ramstyle = "logic" */
);

/* Altera device registers are 0 at power on. Specify this
 * so that Modelsim works as expected.
 */
initial
begin
    for (int i = 0; i < $size(data); i++)
    begin
        data[i].value = '0;
		  data[i].rob_id = `REORDER_ID_INVALID;
    end
end

always_ff @(posedge clk)
begin
    if (load_value == 1 && dest_value != `REGISTER_PC)
    begin
        data[dest_value].value = value_in;
		  data[dest_value].rob_id = `REORDER_ID_INVALID;
    end
	 
	 if (load_rob == 1 && dest_rob != `REGISTER_PC)
    begin
		  data[dest_rob].rob_id = rob_in;
    end
	 
	 // Flush everything (only make it so every register has a valid value)
	 if (flush) begin
		for (int z = 0; z < 7; z++) begin
			data[z].rob_id = `REORDER_ID_INVALID;
		end
	 end
end

endmodule : regfile
