# runs the 1st test on the processor
proc AddWaves {} {
	add wave -position end sim:/processor/clk
	add wave -decimal -position end sim:/processor/pc_if_to_id
	add wave -decimal -position end sim:/processor/i_address
	add wave -position end sim:/processor/i_memread
	add wave -position end sim:/processor/i_waitrequest
	add wave -position end sim:/processor/i_readdata
	add wave -position end sim:/processor/stall_f
	
	add wave -position end sim:/processor/inst
	add wave -position end sim:/processor/fwd1
	add wave -decimal -position end sim:/processor/rd1_2
	add wave -position end sim:/processor/fwd2
	add wave -decimal -position end sim:/processor/rd2_2
	add wave -position end sim:/processor/branch
	add wave -position end sim:/processor/jump
	add wave -position end sim:/processor/link
	add wave -decimal -position end sim:/processor/pc_id_to_ex
	add wave -decimal -position end sim:/processor/imm_out
	add wave -position end sim:/processor/stall_d
	add wave -decimal -position end sim:/processor/reg/reg
	add wave -position end sim:/processor/id/wait_dd
	
	add wave -position end sim:/processor/reg_write_e
	add wave -decimal -position end sim:/processor/write_reg_e
	add wave -position end sim:/processor/alu_mode
	add wave -position end sim:/processor/mem_to_reg_ex
	add wave -position end sim:/processor/mem_write_ex
	add wave -position end sim:/processor/write_data_ex
	add wave -position end sim:/processor/branch_taken
	add wave -decimal -position end sim:/processor/pc_ex_to_if
	add wave -decimal -position end sim:/processor/ex/a/lo
	
	add wave -position end sim:/processor/reg_write_m
	add wave -position end sim:/processor/mem_to_reg_m
	add wave -decimal -position end sim:/processor/write_reg_m
	add wave -decimal -position end sim:/processor/data_m
	add wave -decimal -position end sim:/processor/alu_out_m
	add wave -position end sim:/processor/stall_e
	add wave -decimal -position end sim:/processor/d_address
	add wave -position end sim:/processor/d_memread
	add wave -decimal -position end sim:/processor/d_readdata
	add wave -position end sim:/processor/d_memwrite
	add wave -decimal -position end sim:/processor/d_writedata
	add wave -position end sim:/processor/d_waitrequest
	
	add wave -decimal -position end sim:/processor/write_reg_w
	add wave -position end sim:/processor/reg_write_w
	add wave -decimal -position end sim:/processor/dw
	
}

vlib work
vcom -2008 vhdl/inst_memory.vhd
vcom -2008 vhdl/fetch.vhd
vcom -2008 vhdl/mips_package.vhd
vcom -2008 vhdl/register_file.vhd
vcom -2008 vhdl/ctrl_unit.vhd
vcom -2008 vhdl/decode.vhd
vcom -2008 vhdl/fwd_decode.vhd
vcom -2008 vhdl/ALU.vhd
vcom -2008 vhdl/execute.vhd
vcom -2008 vhdl/data_memory.vhd
vcom -2008 vhdl/memory.vhd
vcom -2008 vhdl/write_back.vhd
vcom -2008 vhdl/pipelined_processor.vhd

vsim processor

force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns

AddWaves

run 10000ns
