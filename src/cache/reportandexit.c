// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern long cachesize, cacnum, cacleng[];
extern long *handptr[];
extern char *lockptr[];
extern char cache_report_size[], cache_report_count[], cache_report_index[];
extern char cache_report_handle[], cache_report_length[], cache_report_lock[];
extern char cache_report_total[];
int printf(const char *format, ...);
void exit(int status);
#pragma aux setvmode =\
    "int 0x10",\
    parm [eax]\

reportandexit()
{
    long i, j;
    setvmode(0x3);
    printf(cache_report_size,cachesize);
    printf(cache_report_count,cacnum);
    j = 0;
    for(i=0;i<cacnum;i++)
    {
        printf(cache_report_index,i);
        printf(cache_report_handle,*handptr[i]);
        printf(cache_report_length,cacleng[i]);
        printf(cache_report_lock,*lockptr[i]);
        j += cacleng[i];
    }
    printf(cache_report_total,j);
    exit(0);
}
