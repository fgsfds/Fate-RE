; Video setup menu and command-line help text.
BITS 32
ORG 0xa51

    db 10, 0
    db 'Graphics mode: %s', 10, 0
    db '   Resolution: %d x %d', 10, 0
    db 'Loading...', 0
    db 27, ' TAB ', 26, 0
    db 'Press ENTER to use the highlighted video', 0
    db 'mode and resolution or ESC to use the default', 0
    db 'of %s @ %dx%d', 0
    db ' Use the UP/DOWN arrow keys ', 0
    db '   to select a video mode   ', 0
    db 'to select a video resolution', 0
    db 'FATE command line options:', 10, 0
    db '     /%-16s %s', 10, 0
    db '.MAP', 0
    db '.', 0
