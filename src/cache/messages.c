// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
/* Cache/archive diagnostic literals; final pooled placement is unresolved. */
char cache_size_format[] = "Cachesize: %ld\n";
char cache_request_format[] = "*Newhandle: 0x%x, Newbytes: %ld, *Newlock: %d\n";
char cache_too_big[] = "BUFFER TOO BIG TO FIT IN CACHE!\n";
char cache_zero_lock[] = "ALLOCACHE CALLED WITH LOCK OF 0!\n";
char cache_all_locked[] = "CACHE SPACE ALL LOCKED UP!\n";
char cache_report_size[] = "Cachesize = %ld\n";
char cache_report_count[] = "Cacnum = %ld\n";
char cache_report_index[] = "%ld- ";
char cache_report_handle[] = "ptr: 0x%x, ";
char cache_report_length[] = "leng: %ld, ";
char cache_report_lock[] = "lock: %ld\n";
char cache_report_total[] = "Cache length sum = %ld\n";
char group_list_allocation_error[] = "Not enough memory for file grouping system\n";
char group_offsets_allocation_error[] = "Not enough memory for file grouping system\n";
char group_too_many_files[] = "TOO MANY FILES OPEN IN FILE GROUPING SYSTEM!";
