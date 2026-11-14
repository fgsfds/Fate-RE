; Slot extensions, file modes, and completion messages for GAMEDATA.
BITS 32
ORG 0x5dc

    db '.G%.2i', 0
    db 'GAMEDATA', 0
    db 'rb', 0
    db 'Game loaded.', 0
    db '.G%.2i', 0
    db 'GAMEDATA', 0
    db 'wb', 0
    db 'Game saved.', 0
