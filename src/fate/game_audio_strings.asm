; Digital audio configuration, sound archive name, and diagnostics.
BITS 32
ORG 0x6d4

    db 'hmiset.cfg', 0
    db 'Could not open hmiset.cfg!', 0
    db 'DIGITAL', 0
    db 'DeviceID', 0
    db 'DevicePort', 0
    db 'DeviceDMA', 0
    db 'DeviceIRQ', 0
    db "setupdigi() : Couldn't malloc mem for digilist!", 0
    db 'sounds', 0
    db "setupdigi() : Couldn't open sounds file", 0
    db 'initsoundfx() : Failure on DIGI System init!', 0
    db 'initsoundfx() : Failure on DIGI Driver init!', 0
    db 'initsoundfx() : Could not register mix function!', 0
    db 'could not read sound config!', 0
    db 'No K_Cache MEM for sounds!', 0
    db 'sampledone() : Num sounds overflow!', 0
    db 'maxsounds violated in stopsound()', 0
    db 'tried to stop a NULL_HANDLE sound', 0
    db 'Error on sosDIGIStopSample() call!', 0
    db 'maxssprites violated in stopspritesound()', 0
    db 'Error on sosDIGIStopSample() call!', 0
    db 'stopped sprnum %d', 0
    db 'Bad SoundNum!', 0
