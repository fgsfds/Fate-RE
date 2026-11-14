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
#pragma aux divscale30 = \
 "mov edx, eax",\
 "sar edx, 2",\
 "shl eax, 30",\
 "idiv ebx",\
 parm nomemory [eax][ebx]\
 modify exact [eax edx]
loadtables()
{
 long i,fil;
 if(tablesloaded==0) {
  initksqrt();
  for(i=0;i<2048;i++)reciptable[i]=divscale30(2048L,i+2048);
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
