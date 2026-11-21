; Original retained gap: Entire original checksum comparison prelude, loop and loop control. Compiler loop-register allocation differs; none of its incidental matching conditions is credited.
BITS 32
ORG 0x32579

board_state_3ce0 equ 0x3ce0
event_read_index equ 0x3ce4
event_write_index equ 0x3cdc
frame_state_1e5fa equ 0x1e5fa
frame_state_1f7fa equ 0x1f7fa
weapon_state_3cda equ 0x3cda
packet_branch_32599 equ 0x32599
packet_branch_325e2 equ 0x325e2

receive_checksum_compare:
    mov eax, [event_write_index]
    mov ecx, [event_read_index]
    cmp eax, ecx
    jz short packet_branch_325e2
    cmp ecx, [board_state_3ce0]
    jz short packet_branch_325e2
    xor esi, esi
    mov [weapon_state_3cda], si
    mov eax, [event_read_index]
    inc eax
    mov cx, [weapon_state_3cda]
    mov dx, [nosplit eax*2 + frame_state_1f7fa]
    mov bx, [nosplit eax*2 + frame_state_1e5fa]
    and eax, strict dword 0xff
    xor edx, ebx
    mov [event_read_index], eax
    or ecx, edx
    mov eax, [event_write_index]
    mov edi, [event_read_index]
    mov [weapon_state_3cda], cx
    cmp eax, edi
    jz short packet_branch_325e2
    cmp edi, [board_state_3ce0]
    jnz short packet_branch_32599
