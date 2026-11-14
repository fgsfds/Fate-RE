; Save slot filenames, diagnostics, and menu captions.
BITS 32
ORG 0xd19

    db 'sss.g00', 0
    db 'sss.g%02d', 0
    db 'svgmnms.sav', 0
    db 'MEN_saveGameOption: cant open save names file', 0
    db 'LEAVING GAME', 0
    db 'MAIN MENU', 0
    db 'LOADING', 0
