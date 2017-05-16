onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mp3_tb/clk
add wave -noupdate -radix decimal /mp3_tb/dut/datapath/fetch/pc_out
add wave -noupdate {/mp3_tb/dut/datapath/decode/instruction_queue/data[3]}
add wave -noupdate {/mp3_tb/dut/datapath/decode/instruction_queue/data[2]}
add wave -noupdate {/mp3_tb/dut/datapath/decode/instruction_queue/data[1]}
add wave -noupdate {/mp3_tb/dut/datapath/decode/instruction_queue/data[0]}
add wave -noupdate {/mp3_tb/dut/datapath/rb/data[0]}
add wave -noupdate {/mp3_tb/dut/datapath/rb/data[1]}
add wave -noupdate {/mp3_tb/dut/datapath/rb/data[2]}
add wave -noupdate {/mp3_tb/dut/datapath/rb/data[3]}
add wave -noupdate {/mp3_tb/dut/datapath/rb/data[4]}
add wave -noupdate {/mp3_tb/dut/datapath/rb/data[5]}
add wave -noupdate {/mp3_tb/dut/datapath/rb/data[6]}
add wave -noupdate {/mp3_tb/dut/datapath/rb/data[7]}
add wave -noupdate {/mp3_tb/dut/datapath/regs/data[4]}
add wave -noupdate {/mp3_tb/dut/datapath/regs/data[3]}
add wave -noupdate {/mp3_tb/dut/datapath/regs/data[2]}
add wave -noupdate {/mp3_tb/dut/datapath/regs/data[1]}
add wave -noupdate /mp3_tb/dut/datapath/decode/stall_output
add wave -noupdate /mp3_tb/dut/datapath/rb/full
add wave -noupdate /mp3_tb/dut/datapath/rb/load
add wave -noupdate /mp3_tb/dut/datapath/rb/head
add wave -noupdate /mp3_tb/dut/datapath/rb/tail
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
radix hex
