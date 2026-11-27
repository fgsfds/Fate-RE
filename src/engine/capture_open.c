// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release.
/* Link the filename formatting and open call within the existing capture frame. */
extern short capture_sequence;
extern int __cdecl open(const char *, int, ...);

int capture_open(char *filename)
{
    filename[4] = (capture_sequence / 1000) % 10 + '0';
    filename[5] = (capture_sequence / 100) % 10 + '0';
    filename[6] = (capture_sequence / 10) % 10 + '0';
    filename[7] = capture_sequence % 10 + '0';
    return open(filename, 0x261, 0x80);
}
