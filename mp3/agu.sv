import lc3b_types::*;
`include "macros.sv"

module agu (
	input lc3b_word base,
	input lc3b_word offset,
	input lc3b_lsq_op op,
	
	output lc3b_word address
);

logic shift;

always_comb
begin
	shift = (op == lq_ldr) || (op == lq_ldi) || (op == sq_str) || (op == sq_sti);
	address = shift ? base + (offset << 1) : base + offset;
end

endmodule : agu