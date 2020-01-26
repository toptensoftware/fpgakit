# Make script
include ../mimasv2.mk

capture: 
	@node ../../../tools/reflector-client/logiccap \
	--port:/dev/ttyACM1 \
	--baud:115200 \
	--sampleRate:1774000 \
	--autoview:150 \
	--bitWidth:49 \
	s_sri_wr s_sri_rd s_sri_wait \
	s_sri_addr[30] s_sri_dout[8] s_sri_din[8]
