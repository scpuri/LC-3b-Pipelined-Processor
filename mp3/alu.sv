import lc3b_types::*;

module alu(
	input lc3b_word a, b,
	input lc3b_aluop op,
	
	output lc3b_word f
);

always_comb
begin
	case (op)	
		alu_add: f = a + b;
		alu_and: f = a & b;
		alu_not: f = ~a;
		alu_shift_left: f = a << b;
		alu_shift_right_logic: f = a >> b;
		alu_shift_right_arith: f = $signed(a) >>> b;
		default: $display("Uknown ALU operation.");
	endcase
end

endmodule : alu