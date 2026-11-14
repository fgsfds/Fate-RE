; Stored menu captions and formatting strings.
BITS 32
ORG 0x1053

    db 'RESET TO DEFAULTS'
    db 0
    db 'PREVIOUS MENU'
    db 0
    db 'KEYBOARD CONFIGURE'
    db 0
    db 'KEYBOARD DEFAULTS'
    db 0
    db '%s %-6s'
    db 0
    db 'KEYBOARD CONFIG'
    db 0
    db 'PRESS A KEY'
    db 0
    db 'BAD CHOICE'
    db 0
    db 'KEYBOARD OPTIONS'
    db 0
    db 'PYMANDROS DEMO'
    db 0
    db 'LESYRGIA DEMO'
    db 0
    db 'PREVIOUS MENU'
    times 2 db 0
    db 'INVENTORY'
    db 0
    db 'KEY DEFAULTS'
    db 0
    db 'ABOUT'
    db 0
    db 'PREVIOUS MENU'
    db 0
    db 'PG FOREWARD'
    db 0
    db 'PG BACKWARD'
    db 0
    db 'GAME PLAY HELP'
    db 0
    db 'HELP OPTIONS'
    times 2 db 0
    db 'MOUSE ENABLE '
    db 0
    db 'LEFT BUTTON  '
    db 0
    db 'MIDDLE BUTTON'
    db 0
    db 'RIGHT BUTTON '
    db 0
    db 'L BTN        '
    db 0
    db 'M BTN        '
    db 0
    db 'R BTN        '
    db 0
    db 'MOUSE X RATE'
    db 0
    db 'MOUSE Y RATE'
    db 0
    db 'PREVIOUS MENU'
    db 0
    db 'MOUSE SENSITIVITY'
    db 0
    db 'MOUSE BUTTONS'
    db 0
    db 'MOUSE CALIBRATION'
    times 3 db 0
    db ' A'
    times 6 db 0
    db '$@%s %s'
    times 2 db 0
    db '%s %13s'
    db 0
    db 'MOUSE CONFIG'
    db 0
    db 'PRESS MOUSE BUTTON'
    db 0
    db 'MOUSE OPTIONS'
    times 4 db 0
    db 'EASY'
    db 0
    db 'MEDIUM'
    db 0
    db 'HARD'
    db 0
    db 'PREVIOUS MENU'
    db 0
    db 'GAME OPTIONS'
    db 0
    db 'SOUND FX VOLUME'
    db 0
    db 'AMBIENT VOLUME'
    db 0
    db 'SOUND FX'
    db 0
    db 'AMBIENT'
    db 0
    db 'PREVIOUS MENU'
    db 0
    db 'SOUND OPTIONS'
    db 0
    db 'STRAFE SPEED'
    db 0
    db 'STRAFE ACCEL'
    db 0
    db 'PREVIOUS MENU'
    db 0
    db 'GENERAL OPTIONS'
    db 0
