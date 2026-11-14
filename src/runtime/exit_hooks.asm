; The runtime replaces these hooks as subsystems are initialized.
BITS 32
ORG 0x141ac

null_exit_offset equ 0x60352 - 0x10000
atexit_hook:     dd null_exit_offset
int23_exit_hook: dd null_exit_offset
fpe_exit_hook:   dd null_exit_offset
