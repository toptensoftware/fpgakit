	.text
	.p2align	1
	.global	_start

_start:
	ldi.l	$sp,__ram_top

	ldi.l   $r0,__data_start
	ldi.l	$r1,0x12345678
	st.l    ($r0),$r1

	ldo.b	$r1, 0($r0)
	ldo.b	$r2, 1($r0)
	ldo.b	$r3, 2($r0)
	ldo.b	$r4, 3($r0)
	sto.b   0($r0),$r1
	sto.b   1($r0),$r2
	sto.b   2($r0),$r3
	sto.b   3($r0),$r4

	ldo.l   $r1, 0($r0);
	
_loop:
	jmpa     _loop


	# Copy data section from ROM to RAM
	ldi.l	$r0,__data_start
	ldi.l	$r1,__data_load
	ldi.l	$r2,__data_end
	sub		$r2,$r0
	jsra	memcpy

	# Zero BSS section
	ldi.l	$r0,__bss_start
	xor		$r1,$r1
	ldi.l	$r2,__bss_end
	sub		$r2,$r0
	jsra	memset

	# Jump to main
	jsra	main

	# Should never get here
	brk

	# This section defines mappings to the hardware
	.section .ports

	.global port_leds_linear		
	.global port_leds_7seg			
	port_leds_linear:		.word	0 	# 0x00
	port_leds_7seg:			.word	0 	# 0x02

