/* Research-only four-body grouping: its shared initializer epilogue DOES NOT
 * match the original. See FRAME-GROUP.md; use frame_prefix.c for exact prefix. */
#ifdef FATE_DOS_SHORT_NAMES
#include "shutdown.c"
#include "selmap.c"
#include "gameloop.c"
#include "initseq.c"
#else
#include "shutdown.c"
#include "select_map.c"
#include "game_loop.c"
#include "init_object_sequences.c"
#endif
