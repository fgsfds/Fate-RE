; Remaining initialized fields, diagnostics and stored zero regions.
BITS 32

game_flags:
    times 3 db 0x01
    db 0x00

data_56:
    times 2 db 0x00

data_108:
    db ' FALLTRIG: MAXFALLTRIG EXCEEDED! '
    times 3 db 0x00
    db ' GET_ICON: CANT FIND ICON_PIC IN LOOKUP TABLE.'
    times 2 db 0x00
    db ' GET_TYPE: CANT FIND SPRTYPE IN LOOKUP TABLE.'
    times 3 db 0x00

data_1b0:
    db ' STARTSEQ: MAX_SEQ_LIST EXCEEDED! '
    times 2 db 0x00

data_1f6:
    times 2 db 0x00

data_219:
    times 3 db 0x00
    db ' SPRMVLST: MAX_SPRUD_LIST EXCEEDED! '
    times 4 db 0x00

data_266:
    times 2 db 0x00

data_285:
    times 3 db 0x00

data_2cf:
    db 0x00

data_2d5:
    times 3 db 0x00

data_376:
    times 2 db 0x00

data_3df:
    db 0x00

data_40b:
    db 0x00

data_40e:
    times 2 db 0x00

data_483:
    db 0x00

data_4c9:
    times 3 db 0x00

data_501:
    times 3 db 0x00
    db 'updowndr.wav'
    times 4 db 0x00
    db 'death.wav'
    db 0x00

data_536:
    times 2 db 0x00
    db 'closdoor.wav'
    times 4 db 0x00
    db 'slime.wav'
    db 0x00
    db 'ouch.wav'
    db 0x00
    db 'water.wav'
    db 0x00
    db 'switch.wav'
    db 0x00
    db "(Player %ld's view)"
    db 0x00
    db 'OUT OF SYNC!'
    db 0x00
    db 'Missed Network packet!'
    db 0x00
    db 'warp.wav'
    times 4 db 0x00
    db 'Player 1 (Master)'
    db 0x00
    db 'Player %ld (Slave)'
    times 4 db 0x00

data_61b:
    db 0x00

data_960:
    db 'VIDMODE'
    db 0x00
    db 0x3f
    db 0x00
    db 'HELP'
    db 0x00
    db 'configure video mode'
    db 0x00
    db 'help screen'
    db 0x00
    db 'CHAIN'
    db 0x00
    db 'VESA'
    db 0x00
    db 'SCREENBUFFER'
    db 0x00
    db 'TSENG'
    db 0x00
    db 'PARADISE'
    db 0x00
    db 'S3CHIPSET'
    db 0x00

data_9cb:
    db '0.90a'
    db 0x00
    db 'FATE DEMO'
    db 0x00
    db '%s V%s'
    db 0x0a
    db 0x00
    db ' %-15s '
    db 0x00
    db 0xb1
    times 15 db ' '
    db 0xb1
    db 0x00
    db 0xb1
    db '  %4d x %4d  '
    db 0xb1
    db 0x00
    times 17 db 0xb1
    db 0x00
    times 18 db 0xb1
    db 0x00
    db 0xb1
    db '  %-12s  '
    db 0xb1
    db 0x00
    db 0xb1
    times 16 db ' '
    db 0xb1
    db 0x00

data_bba:
    times 2 db 0x00

data_cef:
    db 'ON '
    db 0x00
    db 'OFF'
    db 0x00
    db 'GAME OPTIONS'
    db 0x00
    db 'WUSSY JAMBOREE'
    db 0x00
    db '%-16s'
    db 0x00

data_1346:
    times 2 db 0x00

data_1359:
    times 3 db 0x00
    db 'TERM'
    db 0x00
    db '.map'
    times 3 db 0x00
    db 'is_crushsector: invalid sector'
    db 0x00
    db 'clearcrushsector: out of range'
    db 0x00
    db 'ini_crushsectors: out of range'
    db 0x00
    db 'ini_crushsectors: exceeded limit'
    db 0x00
    db 'strt_crushsectors: out of range'
    db 0x00
    db 'strt_crushsectors: not initialized'
    db 0x00
    db 'getcsindx: out of range'
    db 0x00
    db 'getcsindx: not initialized'
    db 0x00

data_1690:
    db 'op_crushsector: out of range'
    db 0x00
    db 'op_crushsector: not initialized'
    db 0x00
    db 'op_crushsector: invalid sector'
    db 0x00
    db 'op_crushsector: csindx not found'
    times 4 db 0x00

data_1747:
    db 0x00

data_18cb:
    db 0x00

data_191d:
    db "Can't allocate conventional memory."
    db 0x0a
    times 3 db 0x00

data_1bd5:
    db 'Tile:%ld'
    db 0x0a
    db 0x00

data_1e8b:
    db 0x00

data_1ec0:
    db 'Not enough memory to allocate file structures'
    db 0x0d
    db 0x0a
    db 0x00

data_1efb:
    db 0x00

data_1f17:
    db 0x00

character_classification:
    times 4 db 0x00
    times 9 db 0x01
    times 5 db 0x03
    times 18 db 0x01
    db 0x0a
    times 15 db 0x0c
    times 10 db '8'
    times 7 db 0x0c
    db 'XXXXXXHHHHHHHHHHHHHHHHHHHH'
    times 6 db 0x0c
    times 6 db 0x98
    times 20 db 0x88
    times 4 db 0x0c
    db 0x01
    times 131 db 0x00

menu_and_text_archive_defaults:
    times 7 db 0x00
    times 4 db 0xff
    times 78 db 0x00
    db 0x01
    times 3 db 0x00
    db 0x01
    times 2 db 0x00
    db 0x80
    times 2 db 0x00
    db 0x08
    times 3 db 0x00
    db 0x0d
    times 3 db 0x00
    db 0x08
    times 3 db 0x00
    db 0x0c
    times 3 db 0x00
    db 0x10
    times 3 db 0x00
    db 0x08
    times 3 db 0x00
    db 0x0a
    times 3 db 0x00
    db 0x10
    times 3 db 0x00
    db 0x08
    times 3 db 0x00

data_13bb0:
    times 16 db 0x00

data_13cd9:
    times 3 db 0x00

data_141a8:
    times 4 db 0x00

data_141b8:
    times 12 db 0x00

data_16a98:
    times 4 db 0x00

data_16ab0:
    times 4 db 0x00

graphics_text_defaults:
    db 0x01
    times 11 db 0x00
    db 0x01
    db 0x07
    db 0x01
    db 0x00
    db 0x01
    times 13 db 0x00
    db 0x03
    db 0x00

graphics_draw_defaults:
    times 4 db 0x00
    times 2 db 0xff
    times 4 db 0x00
    db 0x01
    times 15 db 0x00
    dd 0x1749c         ; DATA-relative pointer.
    times 32 db 0x00

graphics_segment_defaults:
    db 0x34
    db 0x00
    db 0x1c
    db 0x00
    db 0x1c
    db 0x00
    db 0x1c
    db 0x00
    db 0x34
    times 2 db 0x00
    db 0x04
    times 16 db 0x00
    db 0x0c
    db 0x00
    dd 0x2891fc         ; DATA-relative pointer.
    times 3 db 0x00

data_173d8:
    times 48 db 0x00

data_17ec2:
    dw 0

data_199a4:
    times 8 db 0x00
