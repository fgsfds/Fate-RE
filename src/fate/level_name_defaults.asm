; Initial level transition state and the 20-byte board name slots.
BITS 32
ORG 0x202c

    times 3 dd 0                 ; Save state and frame clocks.
    times 4 dw 0                 ; Status icons and input toggle.
    db -1                        ; No pending destination.

%macro board_name 1
    %%start: db %1
    times 20 - ($ - %%start) db 0
%endmacro

    board_name 'nukeland'
    board_name 'v15'
    board_name 'security'
    board_name 'alter'
    board_name 'power'
    board_name 'power2'
    board_name 'basment'
    board_name 'start'
%assign board 8
%rep 17
%if board < 10
    board_name %strcat('tst0', %str(board))
%else
    board_name %strcat('tst', %str(board))
%endif
%assign board board + 1
%endrep
    board_name 'doors'
    board_name 'TERM'
