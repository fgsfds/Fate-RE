/* Natural contiguous callback/main compiler group; no byte or padding scaffold. */
#ifdef FATE_DOS_SHORT_NAMES
#include "maincln.c"
#include "fatemain.c"
#else
#include "main_cleanup.c"
#include "main.c"
#endif
