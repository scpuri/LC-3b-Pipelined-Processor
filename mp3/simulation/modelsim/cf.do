onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mp3_tb/clk
add wave -noupdate /mp3_tb/dut/datapath/common_data_bus/dest
add wave -noupdate /mp3_tb/dut/datapath/common_data_bus/value
add wave -noupdate /mp3_tb/dut/datapath/common_data_bus/update_pc
add wave -noupdate /mp3_tb/dut/datapath/common_data_bus/update_pc_value
add wave -noupdate /mp3_tb/dut/datapath/flush
add wave -noupdate /mp3_tb/dut/datapath/decode/pc
add wave -noupdate /mp3_tb/dut/datapath/decode/instruction
add wave -noupdate /mp3_tb/dut/datapath/decode/reservations_available
add wave -noupdate /mp3_tb/dut/datapath/decode/ld_reservations
add wave -noupdate /mp3_tb/dut/datapath/decode/instruction_queue/head
add wave -noupdate /mp3_tb/dut/datapath/decode/instruction_queue/tail
add wave -noupdate /mp3_tb/dut/datapath/decode/instruction_queue/space_used
add wave -noupdate /mp3_tb/dut/datapath/decode/instruction_queue/data
add wave -noupdate /mp3_tb/dut/datapath/alu_stations/ready
add wave -noupdate /mp3_tb/dut/datapath/alu_stations/outputs
add wave -noupdate /mp3_tb/dut/datapath/alu_stations/data
add wave -noupdate /mp3_tb/dut/datapath/cf_stations/ready
add wave -noupdate /mp3_tb/dut/datapath/cf_stations/outputs
add wave -noupdate /mp3_tb/dut/datapath/cf_stations/data
add wave -noupdate /mp3_tb/dut/datapath/cf_stations/complete
add wave -noupdate /mp3_tb/dut/datapath/cf_stations/finish
add wave -noupdate /mp3_tb/dut/datapath/cf_stations/finish_index
add wave -noupdate /mp3_tb/dut/datapath/cf_stations/pc_taken
add wave -noupdate /mp3_tb/dut/datapath/cf_stations/targets
add wave -noupdate /mp3_tb/dut/datapath/cf_stations/predictions
add wave -noupdate /mp3_tb/dut/datapath/rb/data
add wave -noupdate /mp3_tb/dut/datapath/regs/data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {85000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 375
configure wave -valuecolwidth 153
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {134580 ps}
