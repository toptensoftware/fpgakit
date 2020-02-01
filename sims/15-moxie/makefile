all: firmware simulator

CLEAN += firmware/build

# Make script
include ../isim.mk

FirmwareRom.vhd: ./firmware/build/firmware.bin
	@node ../../tools/bin2vhdlrom/bin2vhdlrom \
		--bigendian \
		--dataWidth:16 \
		--addrWidth:10 \
		./firmware/build/firmware.bin \
		FirmwareRom.vhd

.PHONY: firmware

firmware:
	@cd firmware; $(MAKE) --no-print-directory 

