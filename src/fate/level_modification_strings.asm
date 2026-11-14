; DOS COPY command fragments for saved level modifications.
    db '.G%.2i', 0
    db 'COPY ', 0
    db ' ', 0
    db '.mod', 0
    db ' /Y >sys.log', 0
    db 'SAVE_ENV(): SYSTEM CALL RETURNED %d', 0
    align 8, db 0
    db '.G%.2i', 0
    db 'COPY ', 0
    db '.mod ', 0
    db ' /Y >sys.log', 0
    db 'SAVE_ENV(): SYSTEM CALL RETURNED %d', 0
    db '%3d', 0
    db 'diff_level is 0', 0
