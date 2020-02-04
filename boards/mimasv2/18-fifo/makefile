TARGETBOARD = mimasv2

build: build-bit

upload: upload-bit

# Make script
include ../../../fpgakit.mk


capture: 
	@node $(FPGAKIT)/tools/reflector-client/logiccap \
	--port:/dev/ttyACM1 \
	--baud:115200 \
	--sampleRate:100000000 \
	--autoview:150 \
	s_fifo_write \
	s_fifo_din[8] \
	s_fifo_read \
	s_fifo_dout[8] \
	s_fifo_full \
	s_fifo_empty \
	s_fifo_underflow \
	s_fifo_overflow \
	s_fifo_count[4]