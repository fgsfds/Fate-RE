#ifndef FATE_DOS_IO_H
#define FATE_DOS_IO_H

/* In the demo CRT, open takes stack arguments. The other calls take registers. */
extern int dos_open(const char *filename, int flags, ...);
#pragma aux dos_open "open_" parm caller [] modify exact [eax edx];
extern long lseek(int descriptor, long offset, int origin);
#pragma aux lseek modify exact [eax ebx edx];
extern int read(int descriptor, void *buffer, unsigned count);
#pragma aux read modify exact [eax ebx edx];
extern int write(int descriptor, const void *buffer, unsigned count);
#pragma aux write modify exact [eax ebx edx];
extern int close(int descriptor);
#pragma aux close modify exact [eax];
extern int flushall(void);
#pragma aux flushall modify exact [eax];

#endif
