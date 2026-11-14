/* Controlled placement of named diagnostic arrays; no literal-pool claim. */
#pragma data_seg("CONST", "DATA")
#ifdef FATE_DOS_SHORT_NAMES
#include "cachemsg.c"
#else
#include "messages.c"
#endif
#pragma data_seg()
