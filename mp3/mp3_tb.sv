module mp3_tb;

timeunit 1ns;
timeprecision 1ns;

logic clk;

logic mem_resp_a;
logic mem_read_a;
logic mem_write_a;
logic [1:0] mem_byte_enable_a;
logic [15:0] mem_address_a;
logic [15:0] mem_rdata_a;
logic [15:0] mem_wdata_a;

logic mem_resp_b;
logic mem_read_b;
logic mem_write_b;
logic [1:0] mem_byte_enable_b;
logic [15:0] mem_address_b;
logic [15:0] mem_rdata_b;
logic [15:0] mem_wdata_b;

/* Clock generator */
initial clk = 0;
always #5 clk = ~clk;

mp3 dut
(
    .clk,
	 
    .mem_resp_a,
    .mem_rdata_a,
    .mem_read_a,
    .mem_write_a,
    .mem_byte_enable_a,
    .mem_address_a,
    .mem_wdata_a,
	 
	 .mem_resp_b,
    .mem_rdata_b,
    .mem_read_b,
    .mem_write_b,
    .mem_byte_enable_b,
    .mem_address_b,
    .mem_wdata_b
);

magic_memory_dp memory
(
    .clk,
	 
    .read_a(mem_read_a),
    .write_a(mem_write_a),
    .wmask_a(mem_byte_enable_a),
    .address_a(mem_address_a),
    .wdata_a(mem_wdata_a),
    .resp_a(mem_resp_a),
    .rdata_a(mem_rdata_a),
	 
	 .read_b(mem_read_b),
    .write_b(mem_write_b),
    .wmask_b(mem_byte_enable_b),
    .address_b(mem_address_b),
    .wdata_b(mem_wdata_b),
    .resp_b(mem_resp_b),
    .rdata_b(mem_rdata_b)
);

/*logic [127:0] mem_data;

physical_memory memory
(
	.clk,
	
	 .read(mem_read_a),
    .write(mem_write_a),
    .address(mem_address_a),
    .wdata(128'd0),
    .resp(mem_resp_a),
    .rdata(mem_data)
);

assign mem_rdata_a = (mem_data >> ((mem_address_a[3:1] << 1) * 8)) & 16'hFFFF;*/

endmodule : mp3_tb
