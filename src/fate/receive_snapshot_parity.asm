; Original retained gap: Original count narrowing and parity test; defines incoming ZF for following selected JNE.
BITS 32
ORG 0x32772


receive_snapshot_parity:
    xor ah, ah
    and al, 0x1
    cwde
    test eax, eax
