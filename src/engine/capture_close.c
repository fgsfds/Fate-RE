// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release.
/* Link the success tail after the caller loads its file descriptor. */
extern unsigned short capture_sequence;
extern int close(int);

int capture_close(int fd)
{
    close(fd);
    ++capture_sequence;
    return 0;
}
