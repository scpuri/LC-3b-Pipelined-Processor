onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mp3_tb/clk
add wave -noupdate /mp3_tb/mem_resp_b
add wave -noupdate /mp3_tb/mem_address_b
add wave -noupdate /mp3_tb/mem_read_b
add wave -noupdate /mp3_tb/mem_rdata_b
add wave -noupdate /mp3_tb/mem_write_b
add wave -noupdate /mp3_tb/mem_wdata_b
add wave -noupdate {/mp3_tb/dut/datapath/regs/data[7]}
add wave -noupdate {/mp3_tb/dut/datapath/regs/data[6]}
add wave -noupdate {/mp3_tb/dut/datapath/regs/data[5]}
add wave -noupdate {/mp3_tb/dut/datapath/regs/data[4]}
add wave -noupdate {/mp3_tb/dut/datapath/regs/data[3]}
add wave -noupdate {/mp3_tb/dut/datapath/regs/data[2]}
add wave -noupdate {/mp3_tb/dut/datapath/regs/data[1]}
add wave -noupdate {/mp3_tb/dut/datapath/regs/data[0]}
add wave -noupdate {/mp3_tb/dut/datapath/lsq/loadq[0]}
add wave -noupdate {/mp3_tb/dut/datapath/lsq/loadq[1]}
add wave -noupdate {/mp3_tb/dut/datapath/lsq/loadq[2]}
add wave -noupdate {/mp3_tb/dut/datapath/lsq/loadq[3]}
add wave -noupdate {/mp3_tb/dut/datapath/lsq/loadq[4]}
add wave -noupdate {/mp3_tb/dut/datapath/lsq/loadq[5]}
add wave -noupdate {/mp3_tb/dut/datapath/lsq/loadq[6]}
add wave -noupdate {/mp3_tb/dut/datapath/lsq/loadq[7]}
add wave -noupdate /mp3_tb/dut/datapath/lsq/lq_tail
add wave -noupdate /mp3_tb/dut/datapath/lsq/lq_oldest_ready
add wave -noupdate /mp3_tb/dut/datapath/lsq/waiting
add wave -noupdate {/mp3_tb/dut/datapath/lsq/storeq[0]}
add wave -noupdate {/mp3_tb/dut/datapath/lsq/storeq[1]}
add wave -noupdate {/mp3_tb/dut/datapath/lsq/storeq[2]}
add wave -noupdate {/mp3_tb/dut/datapath/lsq/storeq[3]}
add wave -noupdate {/mp3_tb/dut/datapath/lsq/storeq[4]}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {101622 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {0 ps} {420 ns}
radix hex
