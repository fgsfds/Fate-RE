; Initial HMI detector flags, path buffers, headers and mapped entry state.
BITS 32
ORG 0x16810

    dd 0                        ; Detector flags.
    times 128 db 0              ; Driver directory.
    times 128 db 0              ; Complete driver path.
    times 44 db 0               ; Detector file header.
    times 48 db 0               ; Current entry header.
    times 0x6c db 0              ; Commands and entry metadata.
    times 10 dd 0               ; Far pointers, file state, handle and base.
