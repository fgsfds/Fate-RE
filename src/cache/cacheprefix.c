/* Compile the reconstructed cache/archive prefix in its original function order.
 * Included sources retain their Build attribution and license. Globals remain
 * external; this is not a complete CACHE1D module or final executable link.
 */
#ifdef FATE_DOS_SHORT_NAMES
#include "initcach.c"
#include "allocach.c"
#include "agecache.c"
#include "report.c"
#include "initgr.c"
#include "uninitgr.c"
#include "kopen4.c"
#include "kread.c"
#include "klseek.c"
#include "kfilelen.c"
#include "kclose.c"
#else
#include "initcache.c"
#include "allocache.c"
#include "agecache.c"
#include "reportandexit.c"
#include "initgroupfile.c"
#include "uninitgroupfile.c"
#include "kopen4load.c"
#include "kread.c"
#include "klseek.c"
#include "kfilelength.c"
#include "kclose.c"
#endif
