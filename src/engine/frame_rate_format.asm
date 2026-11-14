; Frame rate format for the engine timing diagnostic.
BITS 32
ORG 0x1bdf

    db '%d.%1d%1d frames per second', 10, 0
