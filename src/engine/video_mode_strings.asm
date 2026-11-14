; Engine signature, video mode diagnostics and table filenames.
BITS 32
ORG 0x1a31

    db 'Nice try.', 10, 0
    db 'tables.dat', 0
    db 'palette.dat', 0
    db '!!!! BUILD engine&tools programmed by Ken Silverman of E.G. RI.  '
    db '(c) Copyright 1995 Ken Silverman.  Summary:  BUILD = Ken. !!!!', 0
    db '%ld * %ld chained mode not supported', 10, 0
