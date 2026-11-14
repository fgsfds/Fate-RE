/* Preserve original source order and shared returns across editor video helpers.
 * Included sources retain their Build attribution/license.
 */
#include "lines.c"
#include "modes16.c"
#ifdef FATE_DOS_SHORT_NAMES
#include "clear2d.c"
#include "grid2d.c"
#else
#include "clear2dscreen.c"
#include "draw2dgrid.c"
#endif
