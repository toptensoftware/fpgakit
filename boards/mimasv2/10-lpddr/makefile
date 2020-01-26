# Make script
include ../mimasv2.mk

capture: 
	@node ../../../tools/reflector-client/logiccap \
	--port:/dev/ttyACM1 \
	--baud:115200 \
	--sampleRate:1774000 \
	--autoview:150 \
	--bitWidth:137 \
	mig_port_cmd_clk \
	mig_port_cmd_en \
	mig_port_cmd_instr[3] \
	mig_port_cmd_bl[6] \
	mig_port_cmd_byte_addr[30] \
	mig_port_cmd_empty \
	mig_port_cmd_full \
	mig_port_wr_clk \
	mig_port_wr_en \
	mig_port_wr_mask[4] \
	mig_port_wr_data[32] \
	mig_port_wr_full \
	mig_port_wr_empty \
	mig_port_wr_count[7] \
	mig_port_wr_underrun \
	mig_port_wr_error \
	mig_port_rd_clk \
	mig_port_rd_en \
	mig_port_rd_data[32] \
	mig_port_rd_full \
	mig_port_rd_empty \
	mig_port_rd_count[7] \
	mig_port_rd_overflow \
	mig_port_rd_error
