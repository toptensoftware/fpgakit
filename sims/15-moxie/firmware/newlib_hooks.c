#include <stdlib.h>

extern void* __bss_end;
extern void* __ram_top;

void* g_pEndOfHeap = NULL;

void* _sbrk_r(int incr)
{
	// First call, set heap base to just after the BSS section
	if (g_pEndOfHeap == NULL)
		g_pEndOfHeap = __bss_end;
	
	// Calculate new heap pointers
	void* pOldEndOfHeap = g_pEndOfHeap;
	void* pNewEndOfHeap = (char*)g_pEndOfHeap + incr;

	// Check for out of memory
	if (pNewEndOfHeap >= __ram_top)
	{
		// Ouch!  How to report this?
	}

	// Done
	g_pEndOfHeap = pNewEndOfHeap;
	return pOldEndOfHeap;
}

