; Key names and fixed-width action captions for the binding menu.
BITS 32
ORG 0xd84

key_names:
    db 0
    db 'ESC', 0, '1', 0, '2', 0, '3', 0, '4', 0, '5', 0, '6', 0, '7', 0
    db '8', 0, '9', 0, '0', 0, '-', 0, '=', 0, 'BKSPC', 0, 'TAB', 0, 'Q', 0
    db 'W', 0, 'E', 0, 'R', 0, 'T', 0, 'Y', 0, 'U', 0, 'I', 0, 'O', 0
    db 'P', 0, '[', 0, ']', 0, 'ENTER', 0, 'LCTRL', 0, 'A', 0, 'S', 0, 'D', 0
    db 'F', 0, 'G', 0, 'H', 0, 'J', 0, 'K', 0, 'L', 0, ';', 0, "'", 0
    db '`', 0, 'LSHFT', 0, '\', 0, 'Z', 0, 'X', 0, 'C', 0, 'V', 0, 'B', 0
    db 'N', 0, 'M', 0, ',', 0, '.', 0, '/', 0, 'RSHFT', 0, 'KPD *', 0, 'L ALT', 0
    db 'SPACE', 0, 'CPSLK', 0, 'F1', 0, 'F2', 0, 'F3', 0, 'F4', 0, 'F5', 0, 'F6', 0
    db 'F7', 0, 'F8', 0, 'F9', 0, 'F10', 0, 'KP NL', 0, 'SCRLK', 0, 'KPD 7', 0, 'KPD 8', 0
    db 'KPD 9', 0, 'KPD -', 0, 'KPD 4', 0, 'KPD 5', 0, 'KPD 6', 0, 'KPD +', 0, 'KPD 1', 0, 'KPD 2', 0
    db 'KPD 3', 0, 'KPD 0', 0, 'KPD .', 0, 'F11', 0, 'F12', 0, 'KP EN', 0, 'RCTRL', 0, 'KPD /', 0
    db 'PRSCR', 0, 'R ALT', 0, 'HOME', 0, 'UPARW', 0, 'PG UP', 0, 'L ARW', 0, 'R ARW', 0, 'END', 0
    db 'DNARW', 0, 'PG DN', 0, 'INS', 0, 'DEL', 0

action_names:
    db 'MOVE FORWARD ', 0
    db 'MOVE BACKWARD', 0
    db 'TURN LEFT    ', 0
    db 'TURN RIGHT   ', 0
    db 'RUN MODE     ', 0
    db 'STRAFE MODE  ', 0
    db 'WEAPON USE 1 ', 0
    db 'OPEN/CLOSE   ', 0
    db 'JUMP         ', 0
    db 'DUCK         ', 0
    db 'LOOK UP      ', 0
    db 'LOOK DOWN    ', 0
    db 'LOOK CENTER  ', 0
    db 'STRAFE LEFT  ', 0
    db 'STRAFE RIGHT ', 0
    db 'MAP MODE     ', 0
    db 'MAP ZOOM IN  ', 0
    db 'MAP ZOOM OUT ', 0
    db 'WEAPON USE 2 ', 0
    db 'STATUS METERS', 0
    db 'INVENTORY    ', 0
    db 'TOSS GRENADE ', 0
    db 'RUN LOCK     ', 0
    db 'INV DISASMBLE', 0
    db 'MOUSE LK UPDN', 0
