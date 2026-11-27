// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern char tablesloaded, tables_filename[];
extern long reciptable[];
extern short sintable[], radarang[];
extern char textfont[],smalltextfont[],britable[];
extern void initksqrt(void);
extern long kopen4load(char *,long),kread(long,void *,long),klseek(long,long,long),kclose(long);
/* Register-only boundaries preserve the original reciprocal-loop allocation.
 * The signed high word and low-word shift are generated from C below. */
long reciprocal_denominator(long),reciprocal_numerator(long,long);
long reciprocal_current_index(void);
#pragma aux reciprocal_denominator = parm nomemory [ebx] value [ebx] modify exact [eax ebx];
#pragma aux reciprocal_numerator = parm nomemory [eax][ecx] value [eax] modify exact [eax];
#pragma aux reciprocal_current_index = value [ecx] modify exact [];
#pragma aux divscale30 = \
 "idiv ebx",\
 parm nomemory [eax][edx][ebx]\
 modify exact [eax edx]
loadtables()
{
 long i,fil,n,d;
 if(tablesloaded==0) {
  initksqrt();
  for(i=0;i<2048;) {
   d=reciprocal_denominator(i+2048);
   n=reciprocal_numerator(2048L,i+1);
   i=reciprocal_current_index();
   reciptable[i-1]=divscale30((unsigned long)n<<30,n>>2,d);
  }
  if((fil=kopen4load(tables_filename,0))!=-1) {
   kread(fil,sintable,2048*2);
   klseek(fil,4096,1);
   kread(fil,radarang,320*2);
   radarang[320]=16384;
   kread(fil,textfont,1024);
   kread(fil,smalltextfont,1024);
   kread(fil,britable,1024);
   kclose(fil);
  }
  tablesloaded=1;
 }
}
