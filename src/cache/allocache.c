// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
/* Pre-March cache algorithm; external bindings are isolated-link inputs. */
#define CAC_HAND(i) handptr[i]
#define CAC_LENG(i) cacleng[i]
#define CAC_LOCK(i) lockptr[i]
extern long cachestart, cachesize, cacnum, cachecount;
extern char zerochar;
extern long cacleng[];
extern char *lockptr[];
extern long *handptr[];
extern char cache_size_format[], cache_request_format[];
extern char cache_too_big[], cache_zero_lock[], cache_all_locked[];
int printf(const char *format, ...);
int reportandexit(void);
#define reportandexit_wrapper(message) do { printf(message); reportandexit(); } while (0)

#pragma aux divscale4 =\
	"mov edx, eax",\
	"sar edx, 28",\
	"shl eax, 4",\
	"idiv ebx",\
	parm nomemory [eax][ebx]\
	modify exact [eax edx]\

allocache (long *newhandle, long newbytes, char *newlockptr)
{
	long i, j, z, zz, bestz, daval, bestval, besto, o1, o2, sucklen, suckz;


	if (newbytes > cachesize)
	{
		printf(cache_size_format,cachesize);
		printf(cache_request_format,newhandle,newbytes,*newlockptr);
		reportandexit_wrapper(cache_too_big);
	}

	if (*newlockptr == 0)
	{
		reportandexit_wrapper(cache_zero_lock);
	}

		//Find best place
	bestval = 0x7fffffff; o1 = 0;
	for(z=0;z<cacnum;z++)
	{
		o2 = o1+newbytes;
		if (o2 > cachesize) break;

		i = o1; daval = 0; zz = z;
		while (i < o2)
		{
			if ((long)*CAC_LOCK(zz) >= 200) { daval = 0x7fffffff; break; }
			if (*CAC_LOCK(zz) > 0)
				daval += divscale4((CAC_LENG(zz)>>10)+64,200-*CAC_LOCK(zz));
			i += CAC_LENG(zz); zz++;
		}
		if (daval < bestval)
		{
			bestval = daval; besto = o1; bestz = z;
		}
		o1 += CAC_LENG(z);
	}

	//printf("%ld %ld %ld\n",besto,newbytes,*newlockptr);

	if (bestval == 0x7fffffff)
		reportandexit_wrapper(cache_all_locked);

		//Suck things out
	for(sucklen=-newbytes,suckz=bestz;sucklen<0;sucklen+=CAC_LENG(suckz++))
		if (*CAC_LOCK(suckz)) *CAC_HAND(suckz) = 0;

		//Remove all blocks except 1
	suckz -= (bestz+1); cacnum -= suckz;
	for(z=bestz;z<cacnum;z++)
	{
		CAC_HAND(z) = CAC_HAND(z+suckz);
		CAC_LENG(z) = CAC_LENG(z+suckz);
		CAC_LOCK(z) = CAC_LOCK(z+suckz);
	}
	CAC_HAND(bestz) = newhandle; *newhandle = cachestart+besto;
	CAC_LENG(bestz) = newbytes;
	CAC_LOCK(bestz) = newlockptr;
	cachecount++;

		//Add new empty block if necessary
	if (sucklen <= 0) return;

	bestz++;
	if (bestz == cacnum)
	{
		cacnum++;
		CAC_LENG(bestz) = sucklen;
		CAC_LOCK(bestz) = &zerochar;
		return;
	}

	if (*CAC_LOCK(bestz) == 0) { CAC_LENG(bestz) += sucklen; return; }

	cacnum++;
	for(z=cacnum-1;z>bestz;z--)
	{
		CAC_HAND(z) = CAC_HAND(z-1);
		CAC_LENG(z) = CAC_LENG(z-1);
		CAC_LOCK(z) = CAC_LOCK(z-1);
	}
	CAC_LENG(bestz) = sucklen;
	CAC_LOCK(bestz) = &zerochar;
}
