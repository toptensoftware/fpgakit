#include <stdlib.h>

// External references to FPGA memory map
extern unsigned char port_leds_linear; 
extern unsigned short port_leds_7seg;

// Simple delay loop
int g_delay = 25000;
void delay()
{
	for (int i=0; i<g_delay; i++)
	{
		__asm__("nop");
	}
}

// Main!
void main()
{
	// Display something on the 7-segment display
	port_leds_7seg = 0xCAFE;

	// Display a rotating bit pattern
	unsigned char bits = 0x03;
	while (1)
	{	
		// Update the LEDs
		port_leds_linear = bits;

		// Rotate the bit pattern
		bits = (bits << 1) | ((bits & 0x80) ? 1 : 0);

		// Not too fast...
		delay();
	}
}