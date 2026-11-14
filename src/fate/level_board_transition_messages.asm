; The save and discard paths retain distinct copies of the diagnostic.
%macro consistency_message 0
    db 10, ' SAVEOLD(): Found Inconsistency!', 10, 0
%endmacro

    consistency_message
    align 4, db 0
    consistency_message
