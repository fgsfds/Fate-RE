/* Compile the line renderers together to preserve their shared return sequence.
 * Included source files retain Ken Silverman's attribution and Build license.
 */
#ifdef FATE_DOS_SHORT_NAMES
#include "line256.c"
#include "line16.c"
#else
#include "drawline256.c"
#include "drawline16.c"
#endif
