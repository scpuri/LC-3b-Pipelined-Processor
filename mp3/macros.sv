`ifndef MACROS
`define MACROS

// Reservation Stations
`define NUM_STATIONS						9  // it was 7, why not 6? added 2 to get 9.
`define NUM_ALU_STATIONS				4
`define NUM_CONTROL_FLOW_STATIONS	2
`define NUM_AGU_STATIONS				2

// Control Flow Types
`define CF_JUMP							'd0
`define CF_BRANCH							'd1
`define CF_JSR								'd2
`define CF_JSRR							'd3
`define CF_TRAP							'd4

// Register value corresponding to pc
`define REGISTER_PC						4'd8

// Reorder Buffer
`define REORDER_BUFFER_SIZE		8
`define REORDER_ID_INVALID			4'd8

// Instruction Queue
`define NUMBER_INSTRUCTION_SLOTS			4
`define BITS_OF_INSTRUCTION_SLOTS		2

// Loadstore queue
`define LQ_SIZE							8
`define SQ_SIZE							8
`define INVALID_ADDRESS					16'bX;

// Branch Prediction
`define BRANCH_PREDICTION_ENABLED		// Comment this out to disable branch prediction
`define TAKEN								1'b1
`define NOT_TAKEN							1'b0
`define HISTORY_WIDTH					3

`endif