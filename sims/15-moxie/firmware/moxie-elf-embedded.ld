OUTPUT_FORMAT("elf32-littlemoxie")
OUTPUT_ARCH(moxie)
ENTRY(_start)

MEMORY 
{
	ROM (rx)       : ORIGIN = 0x00100000, LENGTH = 16k 
	RAM (rwx)      : ORIGIN = 0x00200000, LENGTH = 16k 
    PORTS (rwx)    : ORIGIN = 0x80000000, LENGTH = 1k
} 

SECTIONS
{
 	.startup : 
 	{ 
        *startup.o (.text)
	    . = ALIGN(0x4); 
    } >ROM 

    .text :
    {
    	*(.text) 
	    . = ALIGN(0x4); 
    } >ROM

    .rodata :
    {
    	*(.rodata)
	    . = ALIGN(0x4); 
    } >ROM

    .ramtop : 
    {
        __ram_top = . + LENGTH(RAM);
    } >RAM

    .romdata : 
    { 
	    __data_load = LOADADDR (.romdata); 
        __data_start = .; 
        *(.data .data.* .gnu.linkonce.d.*) 
        . = ALIGN (4); 
	    __data_end = .; 
	} >RAM AT>ROM 


    .bss : 
    { 
        __bss_start = . ; 
        *(.bss .bss.* .gnu.linkonce.b.*) 
        *(COMMON)
        . = ALIGN (4); 
        __bss_end = .; 
    } >RAM

    .ports : 
    {
        *(.ports)    
    } > PORTS
}
