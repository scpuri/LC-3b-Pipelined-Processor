package lc3b_types;

typedef logic [15:0] lc3b_word;
typedef logic  [7:0] lc3b_byte;
typedef logic [127:0] cache_line;
typedef logic [8:0] tag_size;
typedef logic [2:0] lc3b_c_index;

typedef logic  [8:0] lc3b_offset9;
typedef logic  [5:0] lc3b_offset6;

typedef logic  [2:0] lc3b_reg;
typedef logic  [3:0] lc3b_ext_reg;
typedef logic  [2:0] lc3b_nzp;
typedef logic  [1:0] lc3b_mem_wmask;

typedef enum bit [3:0] {
    op_add  = 4'b0001,
    op_and  = 4'b0101,
    op_br   = 4'b0000,
    op_jmp  = 4'b1100,   /* also RET */
    op_jsr  = 4'b0100,   /* also JSRR */
    op_ldb  = 4'b0010,
    op_ldi  = 4'b1010,
    op_ldr  = 4'b0110,
    op_lea  = 4'b1110,
    op_not  = 4'b1001,
    op_rti  = 4'b1000,
    op_shf  = 4'b1101,
    op_stb  = 4'b0011,
    op_sti  = 4'b1011,
    op_str  = 4'b0111,
    op_trap = 4'b1111
} lc3b_opcode;

typedef enum bit [2:0] {
    alu_add,
    alu_and,
    alu_not,
    alu_shift_left,
    alu_shift_right_logic,
	 alu_shift_right_arith
} lc3b_aluop;

typedef struct packed {
	lc3b_word pc;
	lc3b_word instruction;
	logic prediction;				// Branch prediction
} lc3b_iqueue_entry;

typedef enum bit [3:0] {
	res_invalid,
	res_alu_1,
	res_alu_2,
	res_alu_3,
	res_alu_4,
	res_cf_1,
	res_cf_2,
	res_agu_1,
	res_agu_2
} lc3b_rs_id;

typedef logic[3:0] lc3b_rob_id;
typedef logic[3:0] lc3b_lq_id;
typedef logic[3:0] lc3b_sq_id;

typedef struct packed {
	logic [3:0] op;				// Operation to perform
	lc3b_rob_id qj;
	lc3b_rob_id qk;				// Reorder buffer id's producing source operands
	lc3b_word vj;
	lc3b_word vk;					// Values of source operands
	logic rj;
	logic rk;						// Source operands are ready
	lc3b_rob_id dest;				// Reorder buffer id destination
	lc3b_word pc;					// PC of the instruction
	logic busy;						// In use
} lc3b_rs_entry;

typedef struct packed {
	lc3b_word value;
	lc3b_rob_id rob_id;
} lc3b_regfile_entry;

typedef enum bit [2:0] {
	lq_ldr,
	lq_ldb,
	lq_ldi,
	lq_trap,
	sq_str,
	sq_stb,
	sq_sti
} lc3b_lsq_op;

typedef struct packed {
	logic valid;
	lc3b_rob_id rob_id;  // location of instruction in rob
	lc3b_lsq_op op; // type of mem op (ldr, ldi, ldb, trap)
	logic addr_ready; // address received from agu
	lc3b_word address; // memory address for op
	lc3b_word pc;		// PC of instruction (needed for TRAP)
} lc3b_lq_entry;

typedef struct packed {
	logic valid;
	lc3b_rob_id rob_id;  // location of instruction in rob
	lc3b_lsq_op op; // type of mem op
	logic addr_ready; // address received from agu
	lc3b_word address; // memory address for op
	logic val_ready; // value either initially available or from cdb
	lc3b_word value; // value to be stored
	lc3b_rob_id val_rob_id; // rob id of op generating store value
} lc3b_sq_entry;
	
typedef struct packed {
	lc3b_word pc;					// Tag
	lc3b_word target;				// Value
	logic [3:0] op;				// JMP, BR, JSR, JSRR, TRAP (same as in reservation station)
	logic valid;					// Valid
} lc3b_btb_entry;

endpackage : lc3b_types

import lc3b_types::*;

interface lc3b_cdb;
	lc3b_rob_id dest;					// Reorder buffer id of destination
	lc3b_word value;					// Value of register
	lc3b_word update_pc_value;		// New pc value
	logic update_pc;					// Should we update the pc?
	logic ready;						// Indicates operation now complete
endinterface
