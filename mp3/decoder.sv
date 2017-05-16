import lc3b_types::*;
`include "macros.sv"

// Loop through all the reservation stations and output one that is available
// TODO: do something more complex
function lc3b_rs_id find_rs_station(int rs1, int rs2, logic reservations_available[`NUM_STATIONS-1:0]);

for (int z = rs1; z < rs2; z++) begin
	if (reservations_available[z])
		return lc3b_rs_id'(z);
end

return res_invalid;

endfunction

module decoder(
	input lc3b_iqueue_entry data_in,
	input lc3b_ext_reg last_cc_reg,
	input lc3b_regfile_entry data[7:0],
	input logic reservations_available[`NUM_STATIONS-1:0],
	
	output logic[3:0] op_out,
	output lc3b_rob_id qj_out,
	output lc3b_rob_id qk_out,
	output lc3b_word vj_out,
	output lc3b_word vk_out,
	output lc3b_ext_reg dest_reg_out,
	output lc3b_word pc_out,
	output logic prediction_out,
	output lc3b_rs_id res_id_out,
	output lc3b_regfile_entry store_val,
	
	output logic gen_cc,
	output logic lq,
	output logic sq,
	output logic stall_decode
);

lc3b_word imm5;
lc3b_word offset6;
lc3b_reg sr1, sr2, dest;
lc3b_opcode op;
logic is_nop;

always_comb
begin
	// Default values
	pc_out = data_in.pc;
	prediction_out = data_in.prediction;
	op = lc3b_opcode'(data_in.instruction[15:12]);
	imm5 = $signed(data_in.instruction[4:0]);
	offset6 = $signed(data_in.instruction[5:0]);
	sr1 = data_in.instruction[8:6];
	sr2 = data_in.instruction[2:0];
	dest = data_in.instruction[11:9];
	res_id_out = res_invalid;
	is_nop = 1'b0;
	gen_cc = 1'b0;
	
	op_out = '0;
	qj_out = `REORDER_ID_INVALID;
	qk_out = `REORDER_ID_INVALID;
	vj_out = 'x;
	vk_out = 'x;
	dest_reg_out = 'x;
	lq = 0;
	sq = 0;
	store_val = 'x;
	
	// Pick values based on the opcode
	case (op)
		op_add: begin
			op_out = 3'(alu_add);
			qj_out = data[sr1].rob_id;
			qk_out = data_in.instruction[5] ? `REORDER_ID_INVALID : data[sr2].rob_id;
			vj_out = data[sr1].value;
			vk_out = data_in.instruction[5] ? imm5 : data[sr2].value;
			dest_reg_out = dest;
			gen_cc = 1'b1;
			
			res_id_out = find_rs_station(int'(res_alu_1), int'(res_alu_1) + `NUM_ALU_STATIONS, reservations_available);
		end
		op_and: begin
			op_out = 3'(alu_and);
			qj_out = data[sr1].rob_id;
			qk_out = data_in.instruction[5] ? `REORDER_ID_INVALID : data[sr2].rob_id;
			vj_out = data[sr1].value;
			vk_out = data_in.instruction[5] ? imm5 : data[sr2].value;
			dest_reg_out = dest;
			gen_cc = 1'b1;
			
			res_id_out = find_rs_station(int'(res_alu_1), int'(res_alu_1) + `NUM_ALU_STATIONS, reservations_available);
		end
		op_not: begin
			op_out = 3'(alu_not);
			qj_out = data[sr1].rob_id;
			qk_out = `REORDER_ID_INVALID;
			vj_out = data[sr1].value;
			vk_out = '0;
			dest_reg_out = dest;
			gen_cc = 1'b1;
			
			res_id_out = find_rs_station(int'(res_alu_1), int'(res_alu_1) + `NUM_ALU_STATIONS, reservations_available);
		end
		op_shf: begin
			if (data_in.instruction[4])
				op_out = data_in.instruction[5] ? 3'(alu_shift_right_arith) : 3'(alu_shift_right_logic);
			else
				op_out = 3'(alu_shift_left);
			qj_out = data[sr1].rob_id;
			qk_out = `REORDER_ID_INVALID;
			vj_out = data[sr1].value;
			vk_out = 16'(data_in.instruction[3:0]);
			dest_reg_out = dest;
			gen_cc = 1'b1;
			
			res_id_out = find_rs_station(int'(res_alu_1), int'(res_alu_1) + `NUM_ALU_STATIONS, reservations_available);
		end
		op_lea: begin
			// A LEA can be treated as an ADD instruction where DR = (PC + 2) + ADJ9(offset)
			op_out = 3'(alu_add);
			qj_out = `REORDER_ID_INVALID;
			qk_out = `REORDER_ID_INVALID;
			vj_out = data_in.pc + 16'd2;
			vk_out = 16'($signed({ data_in.instruction[8:0], 1'b0 }));
			dest_reg_out = dest;
			gen_cc = 1'b1;
			
			res_id_out = find_rs_station(int'(res_alu_1), int'(res_alu_1) + `NUM_ALU_STATIONS, reservations_available);
		end
		op_jmp: begin
			op_out = 3'(`CF_JUMP);
			qj_out = data[sr1].rob_id;
			qk_out = `REORDER_ID_INVALID;
			vj_out = data[sr1].value;
			vk_out = '0;
			dest_reg_out = `REGISTER_PC;
			
			res_id_out = find_rs_station(int'(res_cf_1), int'(res_cf_1) + `NUM_CONTROL_FLOW_STATIONS, reservations_available);
		end
		op_jsr: begin
			if (data_in.instruction[11] == 1'b1) begin
				// Relative JSR
				op_out = 3'(`CF_JSR);
				qj_out = `REORDER_ID_INVALID;
				vj_out = $signed({ data_in.instruction[10:0], 1'b0 });
			end else begin
				// Register JSRR
				op_out = 3'(`CF_JSRR);
				qj_out = data[sr1].rob_id;
				vj_out = data[sr1].value;
			end
			
			qk_out = `REORDER_ID_INVALID;
			vk_out = '0;
			dest_reg_out = 'd7;
			
			res_id_out = find_rs_station(int'(res_cf_1), int'(res_cf_1) + `NUM_CONTROL_FLOW_STATIONS, reservations_available);
		end
		op_br: begin
			// Handle NOP's by not even putting them in reservation stations
			if (data_in.instruction[11:9] == '0) begin
				is_nop = 1'b1;
			end else if (data_in.instruction[11:9] == 3'b111) begin
				// Handle BRnzp as a JMP
				// TODO: statically predict this branch as taken and its target address
				op_out = 3'(`CF_JUMP);
				qj_out = `REORDER_ID_INVALID;
				qk_out = `REORDER_ID_INVALID;
				vj_out = data_in.pc + 16'd2 + 16'($signed({ data_in.instruction[8:0], 1'b0 }));
				vk_out = '0;
				dest_reg_out = `REGISTER_PC;
			
				res_id_out = find_rs_station(int'(res_cf_1), int'(res_cf_1) + `NUM_CONTROL_FLOW_STATIONS, reservations_available);
			end else begin
				// Handle real branch
				op_out = 3'(`CF_BRANCH);
				qj_out = data[last_cc_reg].rob_id;
				vj_out = data[last_cc_reg].value;
				qk_out = `REORDER_ID_INVALID;
				vk_out = 16'(data_in.instruction[11:0]);
				dest_reg_out = `REGISTER_PC;
			
				res_id_out = find_rs_station(int'(res_cf_1), int'(res_cf_1) + `NUM_CONTROL_FLOW_STATIONS, reservations_available);
			end
		end
		op_ldr: begin
			op_out = 3'(lq_ldr);
			qj_out = data[sr1].rob_id;
			qk_out = `REORDER_ID_INVALID;
			vj_out = data[sr1].value;
			vk_out = offset6;
			dest_reg_out = dest;
			gen_cc = 1'b1;
			lq = 1;
			
			res_id_out = find_rs_station(int'(res_agu_1), int'(res_agu_1) + `NUM_AGU_STATIONS, reservations_available);
		end
		op_ldb: begin
			op_out = 3'(lq_ldb);
			qj_out = data[sr1].rob_id;
			qk_out = `REORDER_ID_INVALID;
			vj_out = data[sr1].value;
			vk_out = offset6;
			dest_reg_out = dest;
			gen_cc = 1'b1;
			lq = 1;
			
			res_id_out = find_rs_station(int'(res_agu_1), int'(res_agu_1) + `NUM_AGU_STATIONS, reservations_available);
		end
		op_ldi: begin
			op_out = 3'(lq_ldi);
			qj_out = data[sr1].rob_id;
			qk_out = `REORDER_ID_INVALID;
			vj_out = data[sr1].value;
			vk_out = offset6;
			dest_reg_out = dest;
			gen_cc = 1'b1;
			lq = 1;
			
			res_id_out = find_rs_station(int'(res_agu_1), int'(res_agu_1) + `NUM_AGU_STATIONS, reservations_available);
		end
		op_trap: begin
			op_out = 3'(lq_trap);
			qj_out = `REORDER_ID_INVALID;
			qk_out = `REORDER_ID_INVALID;
			vj_out = 16'(data_in.instruction[7:0]);
			vk_out = 0;
			dest_reg_out = 'd7;
			lq = 1;
			
			res_id_out = find_rs_station(int'(res_agu_1), int'(res_agu_1) + `NUM_AGU_STATIONS, reservations_available);
		end
		op_str: begin
			op_out = 3'(sq_str);
			qj_out = data[sr1].rob_id;
			qk_out = `REORDER_ID_INVALID;
			vj_out = data[sr1].value;
			vk_out = offset6;
			dest_reg_out = dest;
			gen_cc = 1'b0;
			sq = 1;
			store_val = data[dest];
			
			res_id_out = find_rs_station(int'(res_agu_1), int'(res_agu_1) + `NUM_AGU_STATIONS, reservations_available);
		end
		op_sti: begin
			// TODO: temp
			is_nop = 1'b1;
		end
		default: $display("Uknown opcode.");
	endcase
	
	stall_decode = (res_id_out == res_invalid) && !is_nop;
end

endmodule : decoder